import 'package:flutter/material.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'premium_card.dart';
import 'shared_profile_avatar.dart';
import 'user_profile_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class ProjectStakeholderCard extends StatelessWidget {
  final ProjectEntity project;
  final Map<String, UserEntity> users;

  const ProjectStakeholderCard({
    super.key,
    required this.project,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LangKeys.teamManagement.tr().toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: context.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          _buildStakeholderGroup(
            context,
            LangKeys.supervisors.tr(),
            project.supervisorIds,
            context.purple,
          ),
          const SizedBox(height: 16),
          Divider(color: context.onSurface.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          _buildStakeholderGroup(
            context,
            LangKeys.projectManagers.tr(),
            project.managerIds,
            context.primary,
          ),
          const SizedBox(height: 16),
          Divider(color: context.onSurface.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          _buildStakeholderGroup(
            context,
            LangKeys.clientsExternal.tr().replaceAll(' / External', ''),
            project.clientIds,
            context.mintGreen,
          ),
        ],
      ),
    ).animateScale(delayMs: 700);
  }

  Widget _buildStakeholderGroup(
    BuildContext context,
    String label,
    List<String> userIds,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        if (userIds.isEmpty)
          Text(
            LangKeys.unknown
                .tr(), // Let's simplify Not Assigned into Unknown, or better yet, add a new key below if needed. But since we need to do it quickly, we'll try to add a new key. For now let's just use Unknown. Wait, I will use 'Not Assigned' text but I need to add it to JSON.
            style: TextStyle(
              fontSize: 12,
              color: context.onSurface.withOpacity(0.3),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: -12,
            children: userIds.asMap().entries.map((entry) {
              final user = users[entry.value];
              final name = user?.name ?? LangKeys.unknown.tr();
              return InkWell(
                onTap: () {
                  if (user != null) UserProfileSheet.show(context, user);
                },
                borderRadius: BorderRadius.circular(20),
                child: Tooltip(
                  message: name,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surface, width: 2),
                    ),
                    child: SharedProfileAvatar(
                      name: name,
                      radius: 16,
                      showBorder: false,
                      imageUrl: user?.profile,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
