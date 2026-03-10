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
import '../../core/utils/font_helper.dart';
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.primary.withOpacity(0.12)),
                ),
                child: Icon(
                  Ionicons.people_outline,
                  color: context.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LangKeys.teamManagement.tr().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: context.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.managerIds.length + project.supervisorIds.length + project.workerIds.length + project.clientIds.length} ${LangKeys.users.tr()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if ((widget.project.creatorId == widget.currentUser.id ||
                      (widget.currentUser.role == UserRole.projectManager &&
                          widget.project.managerIds.contains(
                            widget.currentUser.id,
                          ))) &&
                  widget.project.status != ProjectStatus.finished)
                IconButton.filledTonal(
                  onPressed: () {
                    context.push(
                      '/project/${widget.project.id}/manage-users',
                      extra: widget.project,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: context.primary.withOpacity(0.08),
                    foregroundColor: context.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Ionicons.settings_outline, size: 20),
                ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: context.onSurface.withOpacity(0.04),
                  foregroundColor: context.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _isExpanded
                      ? Ionicons.chevron_up_outline
                      : Ionicons.chevron_down_outline,
                  size: 20,
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
                height: 40,
                width: (32 * topMembers.length).toDouble() + 8,
                child: Stack(
                  children: List.generate(topMembers.length, (index) {
                    final userId = topMembers[index];
                    final user = widget.users[userId];
                    return Positioned(
                      left: index * 26,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: context.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SharedProfileAvatar(
                          name: user?.name ?? LangKeys.unknown.tr(),
                          imageUrl: user?.profile,
                          radius: 17,
                          showBorder: false,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              LangKeys.membersTotal.tr(
                args: [
                  [
                    ...project.managerIds,
                    ...project.supervisorIds,
                    ...project.workerIds,
                    ...project.clientIds,
                  ].length.toString(),
                ],
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.onSurface.withOpacity(0.4),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.onSurface.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                if (pm != null) UserProfileSheet.show(context, pm);
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  SharedProfileAvatar(
                    name: pmName,
                    imageUrl: pm?.profile,
                    radius: 24,
                    showBorder: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pmName,
                          style: FontHelper.getTextStyle(
                            pmName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
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
                                color: context.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                LangKeys.getLocalizedRole(
                                  UserRole.projectManager,
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: context.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '· ${LangKeys.workersCount.tr(args: [pmWorkers.length.toString()])}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.onSurface.withOpacity(0.05),
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
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      wName,
                                      style: FontHelper.getTextStyle(
                                        wName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.onSurface.withOpacity(
                                            0.7,
                                          ),
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
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              LangKeys.moreItems.tr(
                                args: [(pmWorkers.length - 10).toString()],
                              ),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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
          SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildUnassignedWorkersRow(
    BuildContext context,
    List<String> unassignedWorkers,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.error.withOpacity(0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.error.withOpacity(0.1), width: 1),
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
                  borderRadius: BorderRadius.circular(12),
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
                    Text(
                      LangKeys.unassignedWorkers.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LangKeys.needsManager.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
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
                            style: FontHelper.getTextStyle(
                              wName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.onSurface.withOpacity(0.7),
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
              if (unassignedWorkers.length > 10)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LangKeys.moreItems.tr(
                      args: [(unassignedWorkers.length - 10).toString()],
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
          spacing: 10,
          runSpacing: 10,
          children: userIds.map((id) {
            final user = widget.users[id];
            final name = user?.name ?? LangKeys.unknown.tr();
            return InkWell(
              onTap: () {
                if (user != null) UserProfileSheet.show(context, user);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                decoration: BoxDecoration(
                  color: context.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.onSurface.withOpacity(0.06),
                  ),
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
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: FontHelper.getTextStyle(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.onSurface.withOpacity(0.8),
                        ),
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
