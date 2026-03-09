import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'premium_card.dart';
import 'shared_profile_avatar.dart';
import 'user_profile_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:go_router/go_router.dart';

class ProjectStakeholderCard extends StatefulWidget {
  final ProjectEntity project;
  final Map<String, UserEntity> users;
  final UserEntity currentUser;

  const ProjectStakeholderCard({
    super.key,
    required this.project,
    required this.users,
    required this.currentUser,
  });

  @override
  State<ProjectStakeholderCard> createState() => _ProjectStakeholderCardState();
}

class _ProjectStakeholderCardState extends State<ProjectStakeholderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final unassignedWorkers = project.workerIds.where((w) {
      final pmId = project.workerManagerMap[w];
      return pmId == null || !project.managerIds.contains(pmId);
    }).toList();

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Ionicons.people_circle_outline,
                      color: context.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        LangKeys.teamManagement.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: context.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.currentUser.role == UserRole.admin &&
                        widget.project.creatorId == widget.currentUser.id &&
                        widget.project.status != ProjectStatus.finished) ...[
                      const SizedBox(width: 8),

                      InkWell(
                        onTap: () {
                          context.push(
                            '/project/${widget.project.id}/manage-users',
                            extra: widget.project,
                          );
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: context.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Ionicons.options_outline,
                                size: 14,
                                color: context.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LangKeys.manageTeam.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
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
            _buildStakeholderGroup(
              context,
              LangKeys.supervisors.tr(),
              project.supervisorIds,
              icon: Ionicons.shield_checkmark_outline,
            ),
            const SizedBox(height: 16),
            Divider(color: context.onSurface.withOpacity(0.05), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Ionicons.git_network_outline,
                  size: 16,
                  color: context.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LangKeys.projectManagers.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (project.managerIds.isEmpty)
              Text(
                LangKeys.unknown.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: context.onSurface.withOpacity(0.3),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: project.managerIds.map((pmId) {
                  final pmWorkers = project.workerIds
                      .where((w) => project.workerManagerMap[w] == pmId)
                      .toList();
                  return _buildManagerTeamRow(context, pmId, pmWorkers);
                }).toList(),
              ),
            if (unassignedWorkers.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildUnassignedWorkersRow(context, unassignedWorkers),
            ],
            const SizedBox(height: 16),
            Divider(color: context.onSurface.withOpacity(0.05), height: 1),
            const SizedBox(height: 16),
            _buildStakeholderGroup(
              context,
              LangKeys.clientsExternal.tr().replaceAll(' / External', ''),
              project.clientIds,
              icon: Ionicons.briefcase_outline,
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildCollapsedSummary(context, project, unassignedWorkers),
          ],
        ],
      ),
    ).animateScale(delayMs: 700);
  }

  Widget _buildCollapsedSummary(
    BuildContext context,
    ProjectEntity project,
    List<String> unassignedWorkers,
  ) {
    // Show top 3 avatars
    final topMembers = [
      ...project.managerIds,
      ...project.supervisorIds,
      ...project.workerIds,
      ...project.clientIds,
    ].take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (topMembers.isNotEmpty)
              SizedBox(
                height: 38,
                width:
                    (38 * 0.8) * topMembers.length +
                    (38 * 0.2), // Overlap logic
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

  Widget _buildManagerTeamRow(
    BuildContext context,
    String pmId,
    List<String> pmWorkers,
  ) {
    final pm = widget.users[pmId];
    final pmName = pm?.name ?? LangKeys.unknown.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.primary.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (pm != null) UserProfileSheet.show(context, pm);
            },
            child: Row(
              children: [
                SharedProfileAvatar(
                  name: pmName,
                  imageUrl: pm?.profile,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pmName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Project Manager',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (pmWorkers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: 24,
                    color: context.primary.withOpacity(0.1),
                    margin: const EdgeInsets.only(right: 12, top: 4),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...pmWorkers.take(10).map((wId) {
                          final worker = widget.users[wId];
                          final wName = worker?.name ?? LangKeys.unknown.tr();
                          return InkWell(
                            onTap: () {
                              if (worker != null) {
                                UserProfileSheet.show(context, worker);
                              }
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: context.primary.withOpacity(0.05),
                                ),
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.onSurface.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (pmWorkers.length > 10)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '+${pmWorkers.length - 10} more',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassignedWorkersRow(
    BuildContext context,
    List<String> unassignedWorkers,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.error.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.error.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Ionicons.warning_outline,
                  color: context.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unassigned Workers',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Needs Manager',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...unassignedWorkers.take(10).map((wId) {
                final worker = widget.users[wId];
                final wName = worker?.name ?? LangKeys.unknown.tr();
                return InkWell(
                  onTap: () {
                    if (worker != null) {
                      UserProfileSheet.show(context, worker);
                    }
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: context.error.withOpacity(0.1)),
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.onSurface.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (unassignedWorkers.length > 10)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '+${unassignedWorkers.length - 10} more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholderGroup(
    BuildContext context,
    String title,
    List<String> userIds, {
    IconData icon = Ionicons.people_outline,
  }) {
    if (userIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: context.onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: userIds.map((id) {
            final user = widget.users[id];
            final name = user?.name ?? LangKeys.unknown.tr();
            return InkWell(
              onTap: () {
                if (user != null) UserProfileSheet.show(context, user);
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: context.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SharedProfileAvatar(
                      name: name,
                      radius: 14,
                      showBorder: false,
                      imageUrl: user?.profile,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
