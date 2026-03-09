import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/theme_ext.dart';
import 'premium_card.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'shared_profile_avatar.dart';

class UserProfileSheet extends StatelessWidget {
  final UserEntity user;

  const UserProfileSheet({super.key, required this.user});

  static void show(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UserProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => PremiumCard(
        borderRadius: 32,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              SharedProfileAvatar(
                name: user.name,
                radius: 48,
                showBorder: true,
                imageUrl: user.profile,
              ),
              const SizedBox(height: 24),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoleBadge(context, user.role),
              const SizedBox(height: 32),
              _buildDetailRow(
                context,
                Ionicons.mail_outline,
                LangKeys.emailAddress.tr(),
                user.email,
              ),
              _buildDetailRow(
                context,
                Ionicons.id_card_outline,
                LangKeys.userId.tr(),
                user.id,
              ),
              if (user.role == UserRole.worker &&
                  user.specialtyName != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Ionicons.briefcase_outline,
                  LangKeys.specialty.tr(),
                  user.specialtyName!,
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, UserRole role) {
    Color color;
    switch (role) {
      case UserRole.admin:
        color = context.primary;
        break;
      case UserRole.supervisor:
        color = context.purple;
        break;
      case UserRole.projectManager:
        color = context.primary;
        break;
      case UserRole.client:
        color = context.mintGreen;
        break;
      case UserRole.worker:
        color = context.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        role.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: context.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: context.onSurface.withOpacity(0.35),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
