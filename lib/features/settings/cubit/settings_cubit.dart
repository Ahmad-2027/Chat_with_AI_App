import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('en'),
    this.error,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? error,
    bool clearError = false,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    error: clearError ? null : error ?? this.error,
  );
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  static const _themeKey = 'dark_mode';
  static const _languageKey = 'language_code';

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      emit(
        state.copyWith(
          themeMode: preferences.getBool(_themeKey) ?? false
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: Locale(preferences.getString(_languageKey) ?? 'en'),
        ),
      );
    } catch (_) {
      emit(state.copyWith(error: 'somethingWentWrong'));
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: mode, clearError: true));
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_themeKey, enabled);
    } catch (_) {
      emit(state.copyWith(error: 'somethingWentWrong'));
    }
  }

  Future<void> setLanguage(String languageCode) async {
    emit(state.copyWith(locale: Locale(languageCode), clearError: true));
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_languageKey, languageCode);
    } catch (_) {
      emit(state.copyWith(error: 'somethingWentWrong'));
    }
  }
}
