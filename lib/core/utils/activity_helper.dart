import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/activity_entity.dart';
import '../localization/lang_keys.dart';

class ActivityHelper {
  /// Extracts the title and subtitle strings depending on the [ActivityType].
  /// This centralized logic allows easy localization.
  static ({String title, String subtitle}) formatActivity({
    required ActivityEntity activity,
    required bool isSystem,
    required String userName,
  }) {
    String title;
    String subtitle;

    switch (activity.type) {
      case ActivityType.taskCreated:
        title = LangKeys.taskCreatedBy.tr(args: [userName]);
        subtitle = activity.content;
        break;
      case ActivityType.projectCreated:
        title = LangKeys.projectCreatedBy.tr(args: [userName]);
        subtitle = activity.content;
        break;
      case ActivityType.taskStatusChanged:
        title = LangKeys.taskStatusChangedTo.tr(args: [activity.content]);
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.projectStatusChanged:
        title = LangKeys.projectStatusChangedTo.tr(args: [activity.content]);
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.taskDeadlineUpdated:
        title = LangKeys.taskDeadlineUpdated.tr();
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.taskApproved:
        title = LangKeys.taskApproved.tr();
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.taskRejected:
        title = LangKeys.taskRejected.tr();
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.projectMembersChanged:
        title = LangKeys.projectMembersChanged.tr();
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.requestCreated:
        // activity.content format: "taskStatus|targetStatus" or "projectStatus|targetStatus"
        final parts = activity.content.split('|');
        final type = parts[0];
        final status = parts.length > 1 ? parts[1] : '';
        title = LangKeys.requestCreatedLog.tr(
          args: [
            type == 'taskStatus'
                ? LangKeys.taskStatus.tr()
                : LangKeys.projectStatus.tr(),
            status,
          ],
        );
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.requestApprovedStep:
        // activity.content format: "stepName|type"
        final parts = activity.content.split('|');
        final step = parts[0];
        final type = parts.length > 1 ? parts[1] : '';
        title = LangKeys.requestApprovedStepLog.tr(
          args: [
            step.toUpperCase(),
            type == 'taskStatus'
                ? LangKeys.taskStatus.tr()
                : LangKeys.projectStatus.tr(),
          ],
        );
        subtitle = LangKeys.byUser.tr(args: [userName]);
        break;
      case ActivityType.requestRejected:
        title = LangKeys.requestRejectedLog.tr();
        subtitle = LangKeys.rejectionReasonLog.tr(args: [activity.content]);
        break;
      case ActivityType.comment:
        title = userName;
        subtitle = activity.content;
        break;
    }

    return (title: title, subtitle: subtitle);
  }
}
