import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../data/repositories/firebase_project_repository_impl.dart';
import '../../presentation/blocs/auth_bloc.dart';
import '../../presentation/blocs/project_bloc.dart';
import '../../presentation/blocs/activity_bloc.dart';
import '../../presentation/blocs/sync_bloc.dart';
import '../../presentation/blocs/theme_bloc.dart';
import '../../presentation/blocs/archive_bloc.dart';
import '../../presentation/blocs/specialty_bloc.dart';
import '../services/notification_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepositoryImpl());
  sl.registerLazySingleton<ProjectRepository>(
    () => FirebaseProjectRepositoryImpl(),
  );

  // BLoCs
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('app_theme_mode');
  final initialMode = ThemeMode.values.firstWhere(
    (e) => e.name == savedTheme,
    orElse: () => ThemeMode.system,
  );

  sl.registerLazySingleton(() => ThemeBloc(initialMode: initialMode));
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(
    () => ProjectBloc(projectRepository: sl(), authRepository: sl()),
  );
  sl.registerFactory(() => ArchiveBloc(projectRepository: sl()));
  sl.registerFactory(() => ActivityBloc(projectRepository: sl()));
  sl.registerFactory(() => SyncBloc(projectRepository: sl()));
  sl.registerFactory(() => SpecialtyBloc(sl()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
}
