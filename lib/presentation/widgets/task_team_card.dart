import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'premium_card.dart';
import 'shared_profile_avatar.dart';
import 'user_profile_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/utils/font_helper.dart';

class TaskTeamCard extends StatefulWidget {
  final TaskEntity task;
  final Map<String, UserEntity> users;
  final UserEntity? currentUser;
  final List<String> projectWorkerIds;
  final Function(List<String>)? onWorkersUpdated;

  const TaskTeamCard({
    super.key,
    required this.task,
    required this.users,
    this.currentUser,
    this.projectWorkerIds = const [],
    this.onWorkersUpdated,
  });

  @override
  State<TaskTeamCard> createState() => _TaskTeamCardState();
}

class _TaskTeamCardState extends State<TaskTeamCard> {
  bool _isExpanded = true;

  Future<bool?> _showConfirmationDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LangKeys.areYouSure.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LangKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LangKeys.confirm.tr(),
              style: TextStyle(color: context.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final users = widget.users;
    final user = widget.currentUser;

    final canManage =
        user != null &&
        (user.role == UserRole.admin ||
            user.role == UserRole.supervisor ||
            user.role == UserRole.projectManager);

    final members = [
      task.creatorId,
      ...task.assignedWorkerIds,
    ].where((id) => id.isNotEmpty).toList();

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Ionicons.people_circle_outline,
                    color: context.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LangKeys.team.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: context.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'View Less' : 'View All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
                            ? Ionicons.chevron_up_outline
                            : Ionicons.chevron_down_outline,
                        size: 14,
                        color: context.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 24),
            _buildUserTile(
              context,
              user: users[task.creatorId],
              label: LangKeys.createdBy.tr(),
              color: context.primary,
              isCreator: true,
            ),
            if (task.assignedWorkerIds.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  height: 1,
                  color: context.onSurface.withAlpha(10),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Ionicons.git_network_outline,
                    size: 16,
                    color: context.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LangKeys.roleWorker.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canManage) _buildAddMemberButton(context),
                    ...task.assignedWorkerIds.take(10).map((wId) {
                      final worker = users[wId];
                      final wName = worker?.name ?? LangKeys.unknown.tr();
                      return InkWell(
                        onTap: () {
                          if (worker != null) {
                            UserProfileSheet.show(context, worker);
                          }
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                          decoration: BoxDecoration(
                            color: context.onSurface.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SharedProfileAvatar(
                                name: wName,
                                imageUrl: worker?.profile,
                                radius: 12,
                                showBorder: false,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  wName,
                                  style: FontHelper.getTextStyle(
                                    wName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.onSurface.withOpacity(0.9),
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (canManage) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () async {
                                    final confirmed =
                                        await _showConfirmationDialog(
                                          context,
                                          LangKeys.confirmWorkerRemove.tr(),
                                        );
                                    if (confirmed == true) {
                                      final newList = List<String>.from(
                                        task.assignedWorkerIds,
                                      )..remove(wId);
                                      widget.onWorkersUpdated?.call(newList);
                                    }
                                  },
                                  child: Icon(
                                    Ionicons.close_circle,
                                    size: 14,
                                    color: context.error.withOpacity(0.5),
                                  ),
                                ),
                              ],
                              SizedBox(width: 5),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (task.assignedWorkerIds.length > 10)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.onSurface.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '+${task.assignedWorkerIds.length - 10} more',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.onSurface.withOpacity(0.9),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.onSurface.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Ionicons.person_outline,
                      color: context.onSurface.withOpacity(0.3),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    LangKeys.unknown.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            _buildCollapsedSummary(context, members),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary(BuildContext context, List<String> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    final topMembers = members.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 38,
              width:
                  (38 * 0.8) * topMembers.length + (38 * 0.2), // Overlap logic
              child: Stack(
                children: List.generate(topMembers.length, (index) {
                  final userId = topMembers[index];
                  final user = widget.users[userId];
                  return Positioned(
                    left: index * (38 * 0.7),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: SharedProfileAvatar(
                        name: user?.name ?? LangKeys.unknown.tr(),
                        imageUrl: user?.profile,
                        radius: 16,
                        showBorder: false,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTile(
    BuildContext context, {
    required UserEntity? user,
    required String label,
    required Color color,
    bool isCreator = false,
  }) {
    if (user == null) return const SizedBox.shrink();

    return Row(
      children: [
        SharedProfileAvatar(
          name: user.name,
          imageUrl: user.profile,
          radius: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: FontHelper.getTextStyle(
                  user.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.onSurface,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  if (user.specialtyName?.isNotEmpty == true ||
                      user.specialtyId?.isNotEmpty == true) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• ${user.specialtyName?.isNotEmpty == true ? user.specialtyName! : user.specialtyId}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface.withOpacity(0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => UserProfileSheet.show(context, user),
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 20,
            color: context.onSurface.withOpacity(0.3),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildAddMemberButton(BuildContext context) {
    return InkWell(
      onTap: () => _showWorkerSelectionSheet(context),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: context.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.add_circle_outline, size: 14, color: context.primary),
            const SizedBox(width: 6),
            Text(
              LangKeys.add.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                LangKeys.roleWorker.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.projectWorkerIds.length,
                itemBuilder: (context, index) {
                  final workerId = widget.projectWorkerIds[index];
                  final worker = widget.users[workerId];
                  final isAssigned = widget.task.assignedWorkerIds.contains(
                    workerId,
                  );

                  if (worker == null) return const SizedBox.shrink();

                  return ListTile(
                    leading: SharedProfileAvatar(
                      name: worker.name,
                      imageUrl: worker.profile,
                      radius: 20,
                    ),
                    title: Text(
                      worker.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      worker.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurface.withOpacity(0.5),
                      ),
                    ),
                    trailing: Icon(
                      isAssigned
                          ? Ionicons.checkmark_circle
                          : Ionicons.add_circle_outline,
                      color: isAssigned ? context.primary : null,
                    ),
                    onTap: () async {
                      final message = isAssigned
                          ? LangKeys.confirmWorkerRemove.tr()
                          : LangKeys.confirmWorkerAdd.tr();
                      final confirmed = await _showConfirmationDialog(
                        context,
                        message,
                      );

                      if (confirmed == true) {
                        final newList = List<String>.from(
                          widget.task.assignedWorkerIds,
                        );
                        if (isAssigned) {
                          newList.remove(workerId);
                        } else {
                          newList.add(workerId);
                        }
                        widget.onWorkersUpdated?.call(newList);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
