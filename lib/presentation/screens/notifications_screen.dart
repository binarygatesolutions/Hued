import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/notification_entity.dart';
import '../../core/utils/font_helper.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/custom_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  /// Returns the Firestore collection ref for the current user's notifications.
  CollectionReference get _notificationsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('notifications');

  Query get _query => _notificationsRef.orderBy('createdAt', descending: true);

  @override
  void initState() {
    super.initState();
    // Automatically mark all notifications as read when the screen opens.
    _markAllRead();
  }

  // ── Mark single notification as read ──────────────────────────────────────
  Future<void> _markRead(String docId) async {
    await _notificationsRef.doc(docId).update({'isRead': true});
  }

  // ── Mark ALL unread notifications as read (batch) ──────────────────────────
  Future<void> _markAllRead() async {
    final unread = await _notificationsRef
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return LangKeys.now.tr();
    if (diff.inMinutes < 60)
      return '${diff.inMinutes}${LangKeys.minutesShort.tr()}';
    if (diff.inHours < 24) return '${diff.inHours}${LangKeys.hoursShort.tr()}';
    if (diff.inDays < 7) return '${diff.inDays}${LangKeys.daysShort.tr()}';
    return DateFormat('MMM d, yyyy', context.locale.toString()).format(dt);
  }

  _NotifStyle _styleFor(String type) {
    switch (type) {
      case 'projectAssigned':
      case 'projectStatusChanged':
        return _NotifStyle(
          icon: Ionicons.folder_outline,
          color: const Color(0xFF7C3AED), // purple
        );
      case 'taskCreated':
      case 'taskAssigned':
        return _NotifStyle(
          icon: Ionicons.checkbox_outline,
          color: const Color(0xFF0EA5E9), // sky blue
        );
      case 'taskApproved':
        return _NotifStyle(
          icon: Ionicons.checkmark_circle_outline,
          color: const Color(0xFF10B981), // green
        );
      case 'taskStatusChanged':
        return _NotifStyle(
          icon: Ionicons.sync_outline,
          color: const Color(0xFFF59E0B), // amber
        );
      case 'taskRejected':
        return _NotifStyle(
          icon: Ionicons.close_circle_outline,
          color: const Color(0xFFEF4444), // red
        );
      default:
        return _NotifStyle(
          icon: Ionicons.information_circle_outline,
          color: const Color(0xFF06B6D4), // cyan
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: CustomLoading()));
    }

    return Scaffold(
      backgroundColor: context.background,
      appBar: SharedAppBar(
        title: LangKeys.notifications.tr(),
        showBackButton: true,
      ),
      body: FirestorePagination(
        query: _query,
        limit: 20,
        viewType: ViewType.list,
        padding: const EdgeInsets.symmetric(vertical: 8),
        onEmpty: _buildEmptyState(),
        itemBuilder: (context, docs, index) {
          final snap = docs[index] as DocumentSnapshot<Map<String, dynamic>>;
          final notif = NotificationEntity.fromFirestore(
            snap.data() ?? {},
            snap.id,
          );
          return _buildItem(notif, index);
        },
      ),
    );
  }

  // ── Notification list item ─────────────────────────────────────────────────
  Widget _buildItem(NotificationEntity notif, int index) {
    final style = _styleFor(notif.type);
    final bgColor = style.color.withValues(alpha: 0.1);

    return InkWell(
      onTap: () => _markRead(notif.id),
      splashColor: style.color.withValues(alpha: 0.05),
      highlightColor: context.onSurface.withValues(alpha: 0.02),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.transparent
              : style.color.withValues(alpha: 0.04),
          border: Border(
            left: BorderSide(
              color: notif.isRead ? Colors.transparent : style.color,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 19),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: FontHelper.getTextStyle(
                              notif.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: context.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread dot
                        if (!notif.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: style.color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notif.body,
                      style: FontHelper.getTextStyle(
                        notif.body,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.onSurface.withValues(alpha: 0.65),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notif.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: index * 40),
      duration: 300.ms,
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: context.onSurface.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Ionicons.notifications_outline,
                size: 64,
                color: context.onSurface.withValues(alpha: 0.2),
              ),
              Positioned(
                top: 32,
                right: 32,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: context.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 12, color: context.surface),
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            LangKeys.noNotifications.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.onSurface,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              LangKeys.noNotificationsSubtitle.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: context.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),
        ],
      ),
    );
  }
}

// ── Style helper ─────────────────────────────────────────────────────────────
class _NotifStyle {
  final IconData icon;
  final Color color;
  const _NotifStyle({required this.icon, required this.color});
}
