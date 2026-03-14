import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:hued/core/utils/haptics_service.dart';
import 'package:hued/presentation/widgets/shared_app_logo.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final UserEntity? user;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.user,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLarge = ResponsiveLayout.isLargeScreen(context);
    final forceExpanded = size.width > 1400;
    final effectivelyExpanded = _isExpanded || forceExpanded;

    if (!isLarge) {
      return Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: _buildBottomBar(
          context,
          showFocusBackground: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.background,
      body: Row(
        children: [
          _buildSidebar(context, forceExpanded, effectivelyExpanded),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: widget.navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    bool forceExpand,
    bool effectivelyExpanded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = [
      (Ionicons.grid_outline, Ionicons.grid, LangKeys.dashboard.tr(), 0),
      (
        Ionicons.pie_chart_outline,
        Ionicons.pie_chart,
        LangKeys.analytics.tr(),
        1,
      ),
      if (widget.user?.role == UserRole.admin)
        (Ionicons.people_outline, Ionicons.people, LangKeys.navUsers.tr(), 2),
      (Ionicons.settings_outline, Ionicons.settings, LangKeys.settings.tr(), 3),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: effectivelyExpanded ? 260 : 100,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: isDark ? 0.3 : 0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              SharedAppLogo(height: 18),
              const SizedBox(height: 48),

              // Navigation Items
              Expanded(
                child: ListView.separated(
                  itemCount: navItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    return _buildNavItem(
                      context,
                      item.$4,
                      item.$1,
                      item.$2,
                      item.$3,
                      isVertical: true,
                      isExpanded: effectivelyExpanded,
                      showFocusBackground: true,
                    );
                  },
                ),
              ),

              // User Info Section
              if (widget.user != null)
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      HapticsService.light();
                      context.pushNamed(AppRouter.updateProfile);
                    },
                    child: Container(
                      padding: EdgeInsets.all(effectivelyExpanded ? 12 : 8),
                      decoration: BoxDecoration(
                        color: context.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: effectivelyExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: widget.user!.profile != null
                                ? NetworkImage(widget.user!.profile!)
                                : null,
                            child: widget.user!.profile == null
                                ? const Icon(Ionicons.person, size: 18)
                                : null,
                          ),
                          if (effectivelyExpanded) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.onSurface,
                                    ),
                                  ),
                                  Text(
                                    LangKeys.getLocalizedRole(
                                      widget.user!.role,
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: context.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Expansion Toggle Button
              if (!forceExpand)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  child: InkWell(
                    onTap: _toggleSidebar,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: effectivelyExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            effectivelyExpanded
                                ? Ionicons.chevron_back
                                : Ionicons.chevron_forward,
                            size: 16,
                            color: context.primary,
                          ),
                          if (effectivelyExpanded) ...[
                            const SizedBox(width: 12),
                            Text(
                              LangKeys.collapse.tr(),
                              style: TextStyle(
                                color: context.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context, {
    bool showFocusBackground = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: context.surface.withOpacity(isDark ? 0.3 : 0.8),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Ionicons.grid_outline,
                  Ionicons.grid,
                  LangKeys.dashboard.tr(),
                  showFocusBackground: showFocusBackground,
                ),
                _buildNavItem(
                  context,
                  1,
                  Ionicons.pie_chart_outline,
                  Ionicons.pie_chart,
                  LangKeys.analytics.tr(),
                  showFocusBackground: showFocusBackground,
                ),
                if (widget.user?.role == UserRole.admin)
                  _buildNavItem(
                    context,
                    2,
                    Ionicons.people_outline,
                    Ionicons.people,
                    LangKeys.navUsers.tr(),
                    showFocusBackground: showFocusBackground,
                  ),
                _buildNavItem(
                  context,
                  3,
                  Ionicons.settings_outline,
                  Ionicons.settings,
                  LangKeys.settings.tr(),
                  showFocusBackground: showFocusBackground,
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
    String label, {
    bool isVertical = false,
    bool isExpanded = false,
    required bool showFocusBackground,
  }) {
    final isActive = widget.navigationShell.currentIndex == index;
    final color = isActive ? context.primary : context.onSurface;
    final opacity = isActive ? 1.0 : 0.5;

    return InkWell(
      onTap: () => widget.navigationShell.goBranch(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 0,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive && showFocusBackground
              ? context.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isVertical
            ? Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: color.withValues(alpha: opacity),
                    size: 22,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: color.withValues(alpha: opacity),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.primary,
                          shape: BoxShape.circle,
                        ),
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.bounceOut,
                      ),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: color.withValues(alpha: opacity),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withValues(alpha: opacity),
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
