import 'package:shared_preferences/shared_preferences.dart';

/// Small scalar app settings ONLY (theme mode, username, onboarding
/// completed flag, etc). All structured/relational data lives in
/// [AppDatabase] via SQLite, per architecture guidelines.
class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUsername = 'username';
  static const String _keyThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String _keyLastSyncAttempt = 'last_sync_attempt';

  Future<bool> get onboardingComplete async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, value);
  }

  Future<String> get username async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? 'Student';
  }

  Future<void> setUsername(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, value);
  }

  Future<String> get themeMode async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, value);
  }

  Future<DateTime?> get lastSyncAttempt async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyLastSyncAttempt);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> setLastSyncAttempt(DateTime value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncAttempt, value.toIso8601String());
  }
}
