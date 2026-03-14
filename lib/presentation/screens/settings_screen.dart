import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:hued/presentation/widgets/shared_app_bar.dart';
import 'package:hued/presentation/widgets/shared_app_logo.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/theme_bloc.dart';
import '../blocs/theme_event.dart';
import '../blocs/theme_state.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/animations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/auth_event.dart';
import '../../domain/entities/entities.dart';
import '../widgets/custom_loading.dart';
import '../widgets/premium_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/project_detail_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;

          return Stack(
            children: [
              const ProjectDetailBackground(),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: SharedAppBar(
                  title: LangKeys.settings.tr(),
                  showBackButton: false,
                  leading: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SharedAppLogo(height: 30),
                  ),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    if (width < 600) {
                      return _buildMobileLayout(context, user);
                    } else if (width < 1000) {
                      return _buildTabletLayout(context, user);
                    } else {
                      return _buildDesktopLayout(context, user);
                    }
                  },
                ),
              ),
            ],
          );
        }
        return const Scaffold(body: CustomLoading());
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context, UserEntity user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildCompactUserHeader(
                context,
                user,
              ).animateEntrance(delayMs: 200),
              const SizedBox(height: 32),
              ..._buildSettingsList(context, user, isDesktop: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactUserHeader(BuildContext context, UserEntity user) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      borderRadius: 32,
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: context.primary.withOpacity(0.08),
            child: Text(
              user.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    color: context.onSurface.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              LangKeys.getLocalizedRole(user.role).toUpperCase(),
              style: TextStyle(
                color: context.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, UserEntity user) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSettingsList(context, user),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section: Interactive User Card
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserCard(context, user).animateEntrance(delayMs: 200),
                    const SizedBox(height: 48),
                    _buildNavHint(context).animateEntrance(delayMs: 400),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              // Right Section: Organized Settings List
              Expanded(
                flex: 2,
                child: Column(
                  children: _buildSettingsList(context, user, isDesktop: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavHint(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LangKeys.managePersonalInfo.tr(),
          style: TextStyle(
            color: context.onSurface.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: context.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserEntity user) {
    return PremiumCard(
      padding: const EdgeInsets.all(40),
      borderRadius: 48,
      child: Column(
        children: [
          Hero(
            tag: 'user_avatar',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.primary.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: context.primary.withOpacity(0.08),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: context.primary,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              user.role.name.toUpperCase(),
              style: TextStyle(
                color: context.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: context.onSurface.withOpacity(0.05)),
          const SizedBox(height: 32),
          _buildUserInfoRow(context, Ionicons.mail_outline, user.email),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: context.onSurface.withOpacity(0.35)),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: context.onSurface.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSettingsList(
    BuildContext context,
    UserEntity user, {
    bool isDesktop = false,
  }) {
    int delay = 400;
    return [
      if (!isDesktop) ...[
        _buildHeader(context, user).animateEntrance(delayMs: delay),
        const SizedBox(height: 24),
      ],

      _sectionHeader(
        context,
        LangKeys.managePersonalInfo.tr(),
      ).animateEntrance(delayMs: delay += 50),
      _settingsGroup([
        _buildSettingTile(
          context,
          icon: Ionicons.person_outline,
          title: LangKeys.editProfile.tr(),
          subtitle: LangKeys.managePersonalInfo.tr(),
          onTap: () => GoRouter.of(context).pushNamed(AppRouter.updateProfile),
          accentColor: context.primary,
          showRoundedCorners: true,
          topOnly: true,
        ),
        _buildDivider(context),
        _buildSettingTile(
          context,
          icon: Ionicons.shield_checkmark_outline,
          title: LangKeys.role.tr(),
          subtitle: user.role.name,
          accentColor: context.mintGreen,
          showRoundedCorners: true,
          bottomOnly: true,
        ),
      ]).animateEntrance(delayMs: delay += 100),

      const SizedBox(height: 32),
      _sectionHeader(
        context,
        LangKeys.appearance.tr(),
      ).animateEntrance(delayMs: delay += 50),
      _settingsGroup([
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return _buildSettingTile(
              context,
              icon: _getThemeIcon(themeState.themeMode),
              title: LangKeys.appTheme.tr(),
              subtitle: _getThemeName(themeState.themeMode),
              accentColor: context.primary,
              onTap: () => _showThemePicker(context, themeState.themeMode),
              showRoundedCorners: true,
              topOnly: true,
            );
          },
        ),
        _buildDivider(context),
        _buildSettingTile(
          context,
          icon: Ionicons.language_outline,
          title: LangKeys.language.tr(),
          subtitle: _getLanguageName(context.locale.languageCode),
          accentColor: context.purple,
          onTap: () => _showLanguagePicker(context),
          showRoundedCorners: true,
          bottomOnly: true,
        ),
      ]).animateEntrance(delayMs: delay += 100),

      const SizedBox(height: 32),
      _sectionHeader(
        context,
        LangKeys.archivedProjects.tr(),
      ).animateEntrance(delayMs: delay += 50),
      _settingsGroup([
        _buildSettingTile(
          context,
          icon: Ionicons.archive_outline,
          title: LangKeys.archivedProjects.tr(),
          subtitle: LangKeys.archivedProjectsSubtitle.tr(),
          accentColor: context.mintGreen,
          onTap: () =>
              GoRouter.of(context).pushNamed(AppRouter.archivedProjects),
          showRoundedCorners: true,
          fullRound: true,
        ),
      ]).animateEntrance(delayMs: delay += 100),

      const SizedBox(height: 32),
      _sectionHeader(
        context,
        LangKeys.aboutHued.tr(),
      ).animateEntrance(delayMs: delay += 50),
      _settingsGroup([
        _buildLinkTile(
          context,
          icon: Ionicons.information_circle_outline,
          title: LangKeys.aboutHued.tr(),
          url: 'https://livehued.com/about-hued.html',
          accentColor: context.primary,
          topOnly: true,
        ),
        _buildDivider(context),
        _buildLinkTile(
          context,
          icon: Ionicons.rocket_outline,
          title: LangKeys.ourServices.tr(),
          url: 'https://livehued.com/our-services.html',
          accentColor: context.purple,
        ),
        _buildDivider(context),
        _buildLinkTile(
          context,
          icon: Ionicons.help_buoy_outline,
          title: LangKeys.supportCentre.tr(),
          url: 'https://livehued.com/contact-us.html',
          accentColor: context.mintGreen,
          bottomOnly: true,
        ),
      ]).animateEntrance(delayMs: delay += 100),

      const SizedBox(height: 48),
      _buildActionTile(
        context,
        icon: Ionicons.log_out_outline,
        title: LangKeys.signOut.tr(),
        onTap: () => _showSignOutConfirmation(context),
        color: context.error,
      ).animateEntrance(delayMs: delay += 100),
      const SizedBox(height: 80),
    ];
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: context.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return GlassContainer(
      opacity: 0.45,
      borderRadius: 28,
      child: Column(children: children),
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity user) {
    return Text(
      LangKeys.settings.tr(),
      style: context.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: context.onSurface,
        letterSpacing: -1.2,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required Color accentColor,
    bool showRoundedCorners = false,
    bool topOnly = false,
    bool bottomOnly = false,
    bool fullRound = false,
  }) {
    final borderRadius = fullRound
        ? BorderRadius.circular(28)
        : topOnly
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : bottomOnly
        ? const BorderRadius.vertical(bottom: Radius.circular(28))
        : BorderRadius.zero;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: context.onSurface.withOpacity(0.7), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: context.onSurface.withOpacity(0.45),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Ionicons.chevron_forward,
              size: 16,
              color: context.onSurface.withOpacity(0.15),
            )
          : null,
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String url,
    required Color accentColor,
    bool topOnly = false,
    bool bottomOnly = false,
  }) {
    final borderRadius = topOnly
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : bottomOnly
        ? const BorderRadius.vertical(bottom: Radius.circular(28))
        : BorderRadius.zero;

    return ListTile(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: context.onSurface.withOpacity(0.7), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      trailing: Icon(
        Ionicons.open_outline,
        size: 16,
        color: context.onSurface.withOpacity(0.15),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GlassContainer(
      opacity: 0.45,
      borderRadius: 24,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color,
          ),
        ),
        trailing: Icon(
          Ionicons.chevron_forward,
          size: 16,
          color: color.withOpacity(0.35),
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Ionicons.sunny_outline;
      case ThemeMode.dark:
        return Ionicons.moon_outline;
      case ThemeMode.system:
        return Ionicons.options_outline;
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return LangKeys.lightTheme.tr();
      case ThemeMode.dark:
        return LangKeys.darkTheme.tr();
      case ThemeMode.system:
        return LangKeys.systemDefault.tr();
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return LangKeys.arabic.tr();
      case 'en':
        return LangKeys.english.tr();
      default:
        return code;
    }
  }

  void _showThemePicker(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.4,
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: PremiumCard(
            borderRadius: 0,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    LangKeys.appearance.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: context.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.light,
                        icon: Ionicons.sunny_outline,
                        title: LangKeys.lightTheme.tr(),
                        currentMode: currentMode,
                        accentColor: context.limeYellow,
                      ),
                      const SizedBox(height: 12),
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.dark,
                        icon: Ionicons.moon_outline,
                        title: LangKeys.darkTheme.tr(),
                        currentMode: currentMode,
                        accentColor: context.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.system,
                        icon: Ionicons.options_outline,
                        title: LangKeys.systemDefault.tr(),
                        currentMode: currentMode,
                        accentColor: context.mintGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required ThemeMode currentMode,
    required Color accentColor,
  }) {
    final isActive = mode == currentMode;
    return ListTile(
      onTap: () {
        context.read<ThemeBloc>().add(SetTheme(mode));
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? context.primary.withOpacity(0.1)
              : context.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive
              ? context.primary
              : context.onSurface.withOpacity(0.35),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          fontSize: 15,
          color: isActive
              ? context.onSurface
              : context.onSurface.withOpacity(0.55),
        ),
      ),
      trailing: isActive
          ? Icon(Ionicons.checkmark_circle, color: context.primary, size: 22)
          : null,
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final locales = [const Locale('en'), const Locale('ar')];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: PremiumCard(
            borderRadius: 0,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    LangKeys.selectLanguage.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: context.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: locales.length,
                    itemBuilder: (context, index) {
                      final locale = locales[index];
                      final isActive = context.locale == locale;
                      return ListTile(
                        onTap: () {
                          context.setLocale(locale);
                          Navigator.pop(context);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? context.primary.withOpacity(0.1)
                                : context.onSurface.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Ionicons.language_outline,
                            color: isActive
                                ? context.primary
                                : context.onSurface.withOpacity(0.35),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getLanguageName(locale.languageCode),
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15,
                            color: isActive
                                ? context.onSurface
                                : context.onSurface.withOpacity(0.55),
                          ),
                        ),
                        trailing: isActive
                            ? Icon(
                                Ionicons.checkmark_circle,
                                color: context.primary,
                                size: 22,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: context.onSurface.withOpacity(0.05)),
        ),
        title: Text(
          LangKeys.signOut.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          LangKeys.signOutConfirm.tr(),
          style: TextStyle(color: context.onSurface.withOpacity(0.6)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LangKeys.cancel.tr(),
              style: TextStyle(
                color: context.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.pop(context);
              },
              child: Text(
                LangKeys.signOut.tr(),
                style: TextStyle(
                  color: context.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, color: context.onSurface.withOpacity(0.04)),
    );
  }
}
