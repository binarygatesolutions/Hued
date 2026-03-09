import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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
import '../../core/utils/responsive_layout.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/auth_event.dart';
import '../../domain/entities/entities.dart';
import '../widgets/custom_loading.dart';
import '../widgets/premium_card.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          final isMobile = ResponsiveLayout.isMobile(context);

          return Scaffold(
            backgroundColor: context.background,
            appBar: SharedAppBar(
              title: LangKeys.settings.tr(),
              showBackButton: false,
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: SharedAppLogo(height: 30),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(color: context.background),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, user),
                          const SizedBox(height: 30),
                          GlassContainer(
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  context,
                                  icon: Ionicons.person_outline,
                                  title: LangKeys.editProfile.tr(),
                                  subtitle: LangKeys.managePersonalInfo.tr(),
                                  onTap: () => context.pushNamed(
                                    AppRouter.updateProfile,
                                  ),
                                  accentColor: context.primary,
                                ),
                                _buildDivider(context),
                                _buildSettingTile(
                                  context,
                                  icon: Ionicons.mail_outline,
                                  title: LangKeys.email.tr(),
                                  subtitle: user.email,
                                  accentColor: context.purple,
                                ),
                                _buildDivider(context),
                                _buildSettingTile(
                                  context,
                                  icon: Ionicons.shield_checkmark_outline,
                                  title: LangKeys.role.tr(),
                                  subtitle: user.role.name.toUpperCase(),
                                  accentColor: context.mintGreen,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          GlassContainer(
                            child: Column(
                              children: [
                                BlocBuilder<ThemeBloc, ThemeState>(
                                  builder: (context, themeState) {
                                    return _buildSettingTile(
                                      context,
                                      icon: _getThemeIcon(themeState.themeMode),
                                      title: LangKeys.appTheme.tr(),
                                      subtitle: _getThemeName(
                                        themeState.themeMode,
                                      ),
                                      accentColor: context.primary,
                                      onTap: () => _showThemePicker(
                                        context,
                                        themeState.themeMode,
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(context),
                                _buildSettingTile(
                                  context,
                                  icon: Ionicons.language_outline,
                                  title: LangKeys.language.tr(),
                                  subtitle: _getLanguageName(
                                    context.locale.languageCode,
                                  ),
                                  accentColor: context.purple,
                                  onTap: () => _showLanguagePicker(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          GlassContainer(
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  context,
                                  icon: Ionicons.archive_outline,
                                  title: LangKeys.archivedProjects.tr(),
                                  subtitle: LangKeys.archivedProjectsSubtitle
                                      .tr(),
                                  accentColor: context.mintGreen,
                                  onTap: () => context.pushNamed(
                                    AppRouter.archivedProjects,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          GlassContainer(
                            child: Column(
                              children: [
                                _buildLinkTile(
                                  context,
                                  icon: Ionicons.information_circle_outline,
                                  title: LangKeys.aboutHued.tr(),
                                  url: 'https://livehued.com/about-hued.html',
                                  accentColor: context.primary,
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
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          GlassContainer(
                            child: ListTile(
                              onTap: () => _showSignOutConfirmation(context),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Ionicons.log_out_outline,
                                  color: context.error,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                LangKeys.signOut.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: context.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: CustomLoading());
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity user) {
    return Text(
      LangKeys.settings.tr(),
      style: context.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onBackground,
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
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.onSurface.withOpacity(0.55), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: context.onSurface.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Ionicons.chevron_forward,
              size: 14,
              color: context.onSurface.withOpacity(0.15),
            )
          : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? context.primary.withOpacity(0.1)
              : context.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive
              ? context.primary
              : context.onSurface.withOpacity(0.3),
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          fontSize: 15,
          color: isActive
              ? context.onSurface
              : context.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: isActive
          ? Icon(Ionicons.checkmark_circle, color: context.primary, size: 18)
          : null,
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String url,
    required Color accentColor,
  }) {
    return ListTile(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.onSurface.withOpacity(0.55), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Icon(
        Ionicons.open_outline,
        size: 14,
        color: context.onSurface.withOpacity(0.2),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: PremiumCard(
            borderRadius: 0,
            padding: EdgeInsets.zero,
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
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        LangKeys.appearance.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: context.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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

  void _showLanguagePicker(BuildContext context) {
    final locales = [const Locale('en'), const Locale('ar')];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: PremiumCard(
            borderRadius: 0,
            padding: EdgeInsets.zero,
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
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        LangKeys.selectLanguage.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: context.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? context.primary.withOpacity(0.1)
                                : context.onSurface.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Ionicons.language_outline,
                            color: isActive
                                ? context.primary
                                : context.onSurface.withOpacity(0.3),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          _getLanguageName(locale.languageCode),
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                            fontSize: 15,
                            color: isActive
                                ? context.onSurface
                                : context.onSurface.withOpacity(0.5),
                          ),
                        ),
                        trailing: isActive
                            ? Icon(
                                Ionicons.checkmark_circle,
                                color: context.primary,
                                size: 18,
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
        title: Text(LangKeys.signOut.tr()),
        content: Text(LangKeys.signOutConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LangKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pop(context);
            },
            child: Text(
              LangKeys.signOut.tr(),
              style: TextStyle(color: context.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: context.onSurface.withOpacity(0.03)),
    );
  }
}
