const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Set global options for v2
setGlobalOptions({ region: "europe-west3" });

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPER: write a notification doc AND push an FCM message to the user
// ─────────────────────────────────────────────────────────────────────────────
async function sendNotificationToUser(userId, title, body, type, data = {}) {
    if (!userId || userId === "system") return;

    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) return;

        const userData = userDoc.data();

        // 1. Write notification to Firestore
        await db.collection("users").doc(userId).collection("notifications").add({
            title,
            body,
            type,
            data,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Send FCM push notification if device token exists
        const fcmToken = userData.fcmToken;
        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: { title, body },
                data: { type, ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) },
                android: {
                    priority: "high",
                    notification: { sound: "default", channelId: "hued_notifications" },
                },
                apns: {
                    payload: { aps: { sound: "default", badge: 1 } },
                },
            };
            await messaging.send(message);
        }
    } catch (err) {
        console.error(`sendNotificationToUser error for ${userId}:`, err);
    }
}

// Helper: send to multiple users at once
async function sendNotificationToUsers(userIds, title, body, type, data = {}) {
    const unique = [...new Set((userIds || []).filter(Boolean))];
    await Promise.all(unique.map((uid) => sendNotificationToUser(uid, title, body, type, data)));
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY TRIGGERS (existing — unchanged)
// ─────────────────────────────────────────────────────────────────────────────

// 1. Trigger when a new Project is created
exports.onProjectCreatedSystem = onDocumentCreated("projects/{projectId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const projectData = snap.data();
    const projectId = event.params.projectId;

    const userId = projectData.creatorId || "system";
    const title = projectData.title || "Untitled Project";

    const activityRef = db.collection("projects").doc(projectId).collection("activities").doc();

    return activityRef.set({
        userId: userId,
        content: title,
        type: "projectCreated",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});

// 2. Trigger when a Project is updated (Status or Members)
exports.onProjectStatusUpdatedSystem = onDocumentUpdated("projects/{projectId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();
    const projectId = event.params.projectId;

    const userId = newData.lastUpdatedBy || "system";
    const activityCollection = db.collection("projects").doc(projectId).collection("activities");
    const promises = [];

    // Check status change
    if (newData.status !== oldData.status) {
        promises.push(activityCollection.doc().set({
            userId: userId,
            content: newData.status,
            type: "projectStatusChanged",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }));
    }

    // Check member additions
    const oldMembersCount = (oldData.supervisorIds?.length || 0) + (oldData.managerIds?.length || 0) + (oldData.clientIds?.length || 0);
    const newMembersCount = (newData.supervisorIds?.length || 0) + (newData.managerIds?.length || 0) + (newData.clientIds?.length || 0);

    if (newMembersCount !== oldMembersCount) {
        promises.push(activityCollection.doc().set({
            userId: userId,
            content: "Members changed",
            type: "projectMembersChanged",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }));
    }

    if (promises.length > 0) {
        return Promise.all(promises);
    }
    return null;
});

// 3. Trigger when a new Task is created
exports.onTaskCreatedSystem = onDocumentCreated("projects/{projectId}/tasks/{taskId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const taskData = snap.data();
    const projectId = event.params.projectId;
    const taskId = event.params.taskId;

    const userId = taskData.creatorId || "system";
    const title = taskData.title || "Untitled Task";

    const taskActivityRef = db
        .collection("projects")
        .doc(projectId)
        .collection("tasks")
        .doc(taskId)
        .collection("activities")
        .doc();

    const projectActivityRef = db
        .collection("projects")
        .doc(projectId)
        .collection("activities")
        .doc();

    const activityData = {
        userId: userId,
        content: title,
        type: "taskCreated",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    return Promise.all([
        taskActivityRef.set(activityData),
        projectActivityRef.set(activityData),
    ]);
});

// 4. Trigger when a Task is updated (Status, Deadline, Approval, Rejection)
exports.onTaskStatusUpdatedSystem = onDocumentUpdated("projects/{projectId}/tasks/{taskId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();
    const projectId = event.params.projectId;
    const taskId = event.params.taskId;

    const userId = newData.lastUpdatedBy || "system";

    const taskActivityCollection = db
        .collection("projects")
        .doc(projectId)
        .collection("tasks")
        .doc(taskId)
        .collection("activities");

    const projectActivityCollection = db
        .collection("projects")
        .doc(projectId)
        .collection("activities");

    const promises = [];

    // Helper to push to both collections
    const addActivityToBoth = (activityData) => {
        promises.push(taskActivityCollection.doc().set(activityData));
        promises.push(projectActivityCollection.doc().set(activityData));
    };

    // Check status change
    if (newData.status !== oldData.status) {
        addActivityToBoth({
            userId: userId,
            content: newData.status,
            type: "taskStatusChanged",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // If status changed to cancelled manually, assume rejected
        if (newData.status === "cancelled" && oldData.status !== "cancelled") {
            addActivityToBoth({
                userId: userId,
                content: "Task rejected",
                type: "taskRejected",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }

    // Check approval
    if (newData.isApproved === true && oldData.isApproved !== true) {
        addActivityToBoth({
            userId: userId,
            content: "Task approved",
            type: "taskApproved",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    // Check deadline update
    const oldDeadline = oldData.deadline?.toMillis ? oldData.deadline.toMillis() : oldData.deadline;
    const newDeadline = newData.deadline?.toMillis ? newData.deadline.toMillis() : newData.deadline;

    if (newDeadline && oldDeadline && newDeadline !== oldDeadline) {
        addActivityToBoth({
            userId: userId,
            content: "Deadline updated",
            type: "taskDeadlineUpdated",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    if (promises.length > 0) {
        return Promise.all(promises);
    }
    return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION TRIGGERS (new)
// ─────────────────────────────────────────────────────────────────────────────

// N1. Project assigned — notify newly-added members
exports.onProjectAssignedNotify = onDocumentUpdated("projects/{projectId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();
    const projectId = event.params.projectId;
    const projectTitle = newData.title || "a project";

    const oldAssigned = new Set([
        ...(oldData.assignedUserIds || []),
        ...(oldData.supervisorIds || []),
        ...(oldData.managerIds || []),
        ...(oldData.clientIds || []),
    ]);

    const newAssigned = [
        ...(newData.assignedUserIds || []),
        ...(newData.supervisorIds || []),
        ...(newData.managerIds || []),
        ...(newData.clientIds || []),
    ];

    // Users that are newly assigned (not in old list)
    const newlyAdded = [...new Set(newAssigned)].filter((uid) => !oldAssigned.has(uid));

    if (newlyAdded.length === 0) return null;

    await sendNotificationToUsers(
        newlyAdded,
        "Assigned to Project",
        `You've been assigned to "${projectTitle}"`,
        "projectAssigned",
        { projectId },
    );
    return null;
});

// N2. Task created — notify all currently assigned project members
exports.onTaskCreatedNotify = onDocumentCreated("projects/{projectId}/tasks/{taskId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const taskData = snap.data();
    const projectId = event.params.projectId;
    const taskId = event.params.taskId;

    const taskTitle = taskData.title || "A new task";
    const creatorId = taskData.creatorId || "system";

    // Fetch the project to get assigned users
    const projectDoc = await db.collection("projects").doc(projectId).get();
    if (!projectDoc.exists) return null;
    const projectData = projectDoc.data();
    const projectTitle = projectData.title || "your project";

    const recipients = [
        ...(projectData.assignedUserIds || []),
        ...(projectData.supervisorIds || []),
        ...(projectData.managerIds || []),
    ].filter((uid) => uid !== creatorId); // don't notify the creator

    await sendNotificationToUsers(
        recipients,
        "New Task Added",
        `"${taskTitle}" was added to "${projectTitle}"`,
        "taskCreated",
        { projectId, taskId },
    );
    return null;
});

// N3. Task updated — notify on status changes, approval, and assignment changes
exports.onTaskUpdatedNotify = onDocumentUpdated("projects/{projectId}/tasks/{taskId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();
    const projectId = event.params.projectId;
    const taskId = event.params.taskId;
    const taskTitle = newData.title || "A task";
    const updatedBy = newData.lastUpdatedBy || "system";

    const promises = [];

    // Status changed
    if (newData.status !== oldData.status) {
        const statusLabels = {
            pending: "Pending",
            inProgress: "In Progress",
            completed: "Completed",
            cancelled: "Cancelled",
        };
        const label = statusLabels[newData.status] || newData.status;

        // Notify the task creator (if different from updater)
        const creatorId = newData.creatorId || oldData.creatorId;
        if (creatorId && creatorId !== updatedBy) {
            promises.push(sendNotificationToUser(
                creatorId,
                "Task Status Updated",
                `"${taskTitle}" is now ${label}`,
                "taskStatusChanged",
                { projectId, taskId, status: newData.status },
            ));
        }

        // Notify project supervisors
        const projectDoc = await db.collection("projects").doc(projectId).get();
        if (projectDoc.exists) {
            const supervisors = (projectDoc.data().supervisorIds || []).filter((uid) => uid !== updatedBy);
            promises.push(sendNotificationToUsers(
                supervisors,
                "Task Status Updated",
                `"${taskTitle}" is now ${label}`,
                "taskStatusChanged",
                { projectId, taskId, status: newData.status },
            ));
        }
    }

    // Task approved
    if (newData.isApproved === true && oldData.isApproved !== true) {
        const creatorId = newData.creatorId || oldData.creatorId;
        if (creatorId && creatorId !== updatedBy) {
            promises.push(sendNotificationToUser(
                creatorId,
                "Task Approved ✅",
                `"${taskTitle}" has been approved`,
                "taskApproved",
                { projectId, taskId },
            ));
        }
    }

    // Task rejected (status -> cancelled)
    if (newData.status === "cancelled" && oldData.status !== "cancelled") {
        const creatorId = newData.creatorId || oldData.creatorId;
        if (creatorId && creatorId !== updatedBy) {
            promises.push(sendNotificationToUser(
                creatorId,
                "Task Cancelled",
                `"${taskTitle}" has been cancelled`,
                "taskRejected",
                { projectId, taskId },
            ));
        }
    }

    // Newly assigned task members
    const oldAssignedIds = new Set(oldData.assignedUserIds || []);
    const newAssignedIds = newData.assignedUserIds || [];
    const newlyAssigned = newAssignedIds.filter((uid) => !oldAssignedIds.has(uid) && uid !== updatedBy);
    if (newlyAssigned.length > 0) {
        promises.push(sendNotificationToUsers(
            newlyAssigned,
            "Assigned to Task",
            `You've been assigned to "${taskTitle}"`,
            "taskAssigned",
            { projectId, taskId },
        ));
    }

    if (promises.length > 0) {
        await Promise.all(promises);
    }
    return null;
});

// N4. Project status changed — notify all assigned members
exports.onProjectStatusChangedNotify = onDocumentUpdated("projects/{projectId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();
    const projectId = event.params.projectId;

    if (newData.status === oldData.status) return null;

    const projectTitle = newData.title || "A project";
    const updatedBy = newData.lastUpdatedBy || "system";
    const statusLabels = {
        inProgress: "In Progress",
        canceled: "Cancelled",
        finished: "Finished 🎉",
    };
    const label = statusLabels[newData.status] || newData.status;

    const recipients = [
        ...(newData.assignedUserIds || []),
        ...(newData.supervisorIds || []),
        ...(newData.managerIds || []),
        ...(newData.clientIds || []),
    ].filter((uid) => uid !== updatedBy);

    await sendNotificationToUsers(
        recipients,
        "Project Status Updated",
        `"${projectTitle}" is now ${label}`,
        "projectStatusChanged",
        { projectId, status: newData.status },
    );
    return null;
});
