import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/settings_store.dart';

/// Persisted theme mode ('system' | 'light' | 'dark'), exposed as a
/// Flutter [ThemeMode] for direct use in [MaterialApp.themeMode].
///
/// Kept as a simple synchronous-looking StateNotifier (backed by async
/// SharedPreferences reads/writes under the hood) so the root widget can
/// watch it without an AsyncValue wrapper — defaults to system while the
/// stored preference loads.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final String stored = await SettingsStore.instance.themeMode;
    state = _fromStored(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await SettingsStore.instance.setThemeMode(_toStored(mode));
  }

  ThemeMode _fromStored(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toStored(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((Ref ref) {
  return ThemeModeNotifier();
});

/// Whether onboarding has been completed, read once at app start to
/// decide the initial route.
final FutureProvider<bool> onboardingCompleteProvider = FutureProvider<bool>((Ref ref) {
  return SettingsStore.instance.onboardingComplete;
});

/// The user's display name, shown on Home/Profile/Leaderboard.
final FutureProvider<String> usernameProvider = FutureProvider<String>((Ref ref) {
  return SettingsStore.instance.username;
});
