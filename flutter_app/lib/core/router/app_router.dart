import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/chest/presentation/daily_chest_screen.dart';
import '../../features/cosmetics/presentation/cosmetics_screen.dart';
import '../../features/course_map/presentation/course_map_screen.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/duel/presentation/duel_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/mini_project/presentation/mini_project_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/pet/presentation/pet_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quests/presentation/weekly_quests_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/weekly_report/presentation/weekly_report_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../providers/settings_provider.dart';

/// Flips to `true` once the animated [SplashScreen]'s intro/hold/exit
/// sequence has finished. The router's `redirect` waits on this in
/// addition to [onboardingCompleteProvider] so the splash always plays
/// out in full — even on a warm start where the onboarding-complete
/// read resolves instantly — instead of being skipped or cut short.
final StateProvider<bool> splashFinishedProvider = StateProvider<bool>((Ref ref) => false);

/// Route path constants — kept centralized so features never hardcode
/// path strings inline.
class AppRoutes {
  const AppRoutes._();
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String learn = '/learn';
  static const String courseMap = '/learn/:courseId';
  static const String lesson = '/lesson/:lessonId';
  static const String miniProject = '/project/:projectId';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
  static const String achievements = '/achievements';
  static const String dailyChallenge = '/daily-challenge';
  static const String shop = '/shop';
  static const String weeklyQuests = '/quests';
  static const String dailyChest = '/chest';
  static const String pet = '/pet';
  static const String duel = '/duel';
  static const String cosmetics = '/cosmetics';
  static const String weeklyReport = '/weekly-report';

  static String courseMapPath(String courseId) => '/learn/$courseId';
  static String lessonPath(String lessonId, {required String courseId, required String topicId}) =>
      '/lesson/$lessonId?courseId=$courseId&topicId=$topicId';
  static String miniProjectPath(String projectId, {required String topicId}) =>
      '/project/$projectId?topicId=$topicId';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final bool goingToSplash = state.matchedLocation == AppRoutes.splash;

      // The animated splash always gets to play out in full before any
      // redirect fires — otherwise a fast cold start (onboarding flag
      // already resolved) could redirect away mid-animation.
      final bool splashFinished = ref.watch(splashFinishedProvider);
      if (!splashFinished) return goingToSplash ? null : AppRoutes.splash;

      final AsyncValue<bool> onboardingComplete = ref.watch(onboardingCompleteProvider);
      // While the async preference read is in flight, don't redirect yet
      // — avoids a flash to /onboarding for returning users on cold start.
      // If the read fails outright (corrupted prefs, platform-channel
      // error), fall back to `false` rather than stalling forever on a
      // blank screen — worst case a returning user re-sees onboarding.
      final bool? complete = onboardingComplete.hasError ? false : onboardingComplete.valueOrNull;
      if (complete == null) return null;

      final bool goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (goingToSplash) return complete ? AppRoutes.home : AppRoutes.onboarding;
      if (!complete && !goingToOnboarding) return AppRoutes.onboarding;
      if (complete && goingToOnboarding) return AppRoutes.home;
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return SplashScreen(
            onFinished: () => ref.read(splashFinishedProvider.notifier).state = true,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.learn,
            builder: (BuildContext context, GoRouterState state) => const LearnScreen(),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (BuildContext context, GoRouterState state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.courseMap,
        builder: (BuildContext context, GoRouterState state) {
          final String courseId = state.pathParameters['courseId']!;
          return CourseMapScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: AppRoutes.lesson,
        builder: (BuildContext context, GoRouterState state) {
          final String lessonId = state.pathParameters['lessonId']!;
          final String courseId = state.uri.queryParameters['courseId'] ?? '';
          final String topicId = state.uri.queryParameters['topicId'] ?? '';
          return LessonScreen(lessonId: lessonId, courseId: courseId, topicId: topicId);
        },
      ),
      GoRoute(
        path: AppRoutes.miniProject,
        builder: (BuildContext context, GoRouterState state) {
          final String projectId = state.pathParameters['projectId']!;
          final String topicId = state.uri.queryParameters['topicId'] ?? '';
          return MiniProjectScreen(projectId: projectId, topicId: topicId);
        },
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (BuildContext context, GoRouterState state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyChallenge,
        builder: (BuildContext context, GoRouterState state) => const DailyChallengeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (BuildContext context, GoRouterState state) => const ShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyQuests,
        builder: (BuildContext context, GoRouterState state) => const WeeklyQuestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyChest,
        builder: (BuildContext context, GoRouterState state) => const DailyChestScreen(),
      ),
      GoRoute(
        path: AppRoutes.pet,
        builder: (BuildContext context, GoRouterState state) => const PetScreen(),
      ),
      GoRoute(
        path: AppRoutes.duel,
        builder: (BuildContext context, GoRouterState state) => const DuelScreen(),
      ),
      GoRoute(
        path: AppRoutes.cosmetics,
        builder: (BuildContext context, GoRouterState state) => const CosmeticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyReport,
        builder: (BuildContext context, GoRouterState state) => const WeeklyReportScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod's [onboardingCompleteProvider] and
/// [splashFinishedProvider] into a single [Listenable] so GoRouter
/// re-evaluates its `redirect` callback the moment either resolves,
/// instead of only on navigation events.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    _onboardingSub = ref.listen<AsyncValue<bool>>(
      onboardingCompleteProvider,
      (AsyncValue<bool>? previous, AsyncValue<bool> next) => notifyListeners(),
    );
    _splashSub = ref.listen<bool>(
      splashFinishedProvider,
      (bool? previous, bool next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<bool>> _onboardingSub;
  late final ProviderSubscription<bool> _splashSub;

  @override
  void dispose() {
    _onboardingSub.close();
    _splashSub.close();
    super.dispose();
  }
}
