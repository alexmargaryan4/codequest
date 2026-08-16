import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:codequest/main.dart';

void main() {
  // `sqflite` normally talks to platform-native SQLite over a method
  // channel that doesn't exist in `flutter test`'s headless environment.
  // Swapping in the FFI-backed factory lets AppDatabase's real
  // `openDatabase` calls work against an in-memory/native SQLite build
  // instead, without touching any app code.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
    'CodeQuestApp builds without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CodeQuestApp()),
      );

      // Let the first frame (and onboarding/home routing) settle.
      await tester.pump(const Duration(milliseconds: 500));

      // The app should have rendered a MaterialApp-backed widget tree
      // without throwing during build.
      expect(find.byType(MaterialApp), findsOneWidget);
    },
    // A per-test ceiling so a genuine hang (e.g. native SQLite/FFI
    // blocking instead of throwing on a CI runner) fails this specific
    // test with a clear "test timed out" message pointing at this file,
    // instead of the whole `flutter test` process sitting there until
    // the surrounding CI job's own timeout (or GitHub's 6-hour default)
    // finally kills it with no indication of where it got stuck.
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
