import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _themeKey = 'app_theme_mode';

  ThemeBloc({ThemeMode initialMode = ThemeMode.system})
    : super(ThemeState(initialMode)) {
    on<ToggleTheme>((event, emit) async {
      final nextTheme =
          state.themeMode == ThemeMode.dark ||
              state.themeMode == ThemeMode.system
          ? ThemeMode.light
          : ThemeMode.dark;
      emit(ThemeState(nextTheme));
      await _saveTheme(nextTheme);
    });

    on<SetTheme>((event, emit) async {
      emit(ThemeState(event.themeMode));
      await _saveTheme(event.themeMode);
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }
}
