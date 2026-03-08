import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final UserEntity? user;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Expanded(child: navigationShell),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: isMobile ? 80 : 70,
          decoration: BoxDecoration(
            color: context.surface.withOpacity(isDark ? 0.3 : 0.8),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 0 : 40,
              right: isMobile ? 0 : 40,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Ionicons.grid_outline,
                  Ionicons.grid,
                  LangKeys.dashboard.tr(),
                ),
                _buildNavItem(
                  context,
                  1,
                  Ionicons.pie_chart_outline,
                  Ionicons.pie_chart,
                  LangKeys.analytics.tr(),
                ),
                if (user?.role == UserRole.admin)
                  _buildNavItem(
                    context,
                    2,
                    Ionicons.people_outline,
                    Ionicons.people,
                    LangKeys.navUsers.tr(),
                  ),
                _buildNavItem(
                  context,
                  3,
                  Ionicons.settings_outline,
                  Ionicons.settings,
                  LangKeys.settings.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = navigationShell.currentIndex == index;
    final color = isActive
        ? context.primary
        : context.onSurface.withOpacity(0.4);

    return InkWell(
      onTap: () => navigationShell.goBranch(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
