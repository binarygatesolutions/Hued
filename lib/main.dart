import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/localization/lang_keys.dart';
import 'core/services/notification_service.dart';
import 'core/utils/injection_container.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/auth_event.dart';
import 'presentation/blocs/project_bloc.dart';
import 'presentation/blocs/theme_bloc.dart';
import 'presentation/blocs/theme_state.dart';
import 'presentation/blocs/archive_bloc.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/project_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initDependencies();
  await sl<NotificationService>().init();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/l10n',
      fallbackLocale: const Locale('en'),
      child: const HuedApp(),
    ),
  );
}

class HuedApp extends StatelessWidget {
  const HuedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => sl<AuthRepository>()),
        RepositoryProvider<ProjectRepository>(
          create: (_) => sl<ProjectRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()),
          BlocProvider<ProjectBloc>(create: (_) => sl<ProjectBloc>()),
          BlocProvider<ArchiveBloc>(create: (_) => sl<ArchiveBloc>()),
          BlocProvider<AuthBloc>(
            create: (_) => sl<AuthBloc>()..add(CheckAuthStatus()),
          ),
        ],
        child: const HuedAppContent(),
      ),
    );
  }
}

class HuedAppContent extends StatefulWidget {
  const HuedAppContent({super.key});

  @override
  State<HuedAppContent> createState() => _HuedAppContentState();
}

class _HuedAppContentState extends State<HuedAppContent> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context.read<AuthBloc>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp.router(
          title: LangKeys.appTitle.tr(),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(context.locale.languageCode),
          darkTheme: AppTheme.getDarkTheme(context.locale.languageCode),
          themeMode: state.themeMode,
          routerConfig: _router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
