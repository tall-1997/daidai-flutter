import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStyleSettings {
  final ThemeMode themeMode;

  const AppStyleSettings({
    this.themeMode = ThemeMode.system,
  });

  AppStyleSettings copyWith({
    ThemeMode? themeMode,
  }) {
    return AppStyleSettings(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppStyleNotifier extends StateNotifier<AppStyleSettings> {
  AppStyleNotifier() : super(const AppStyleSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;

    state = AppStyleSettings(
      themeMode: ThemeMode.values[themeIndex],
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

final appStyleProvider =
    StateNotifierProvider<AppStyleNotifier, AppStyleSettings>((ref) {
  return AppStyleNotifier();
});

// 兼容旧代码
final themeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appStyleProvider).themeMode;
});
