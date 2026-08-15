import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_database.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up the SQLite database once at startup so the first screen
  // never has to wait on a cold `openDatabase` call mid-build.
  await AppDatabase.instance.database;

  runApp(const ProviderScope(child: CodeQuestApp()));
}

class CodeQuestApp extends ConsumerWidget {
  const CodeQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CodeQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
