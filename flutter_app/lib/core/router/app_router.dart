import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/course_map/presentation/course_map_screen.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/mini_project/presentation/mini_project_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quests/presentation/weekly_quests_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../providers/settings_provider.dart';

/// Route path constants — kept centralized so features never hardcode
/// path strings inline.
class AppRoutes {
  const AppRoutes._();
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

  static String courseMapPath(String courseId) => '/learn/$courseId';
  static String lessonPath(String lessonId, {required String courseId, required String topicId}) =>
      '/lesson/$lessonId?courseId=$courseId&topicId=$topicId';
  static String miniProjectPath(String projectId, {required String topicId}) =>
      '/project/$projectId?topicId=$topicId';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<bool> onboardingComplete = ref.watch(onboardingCompleteProvider);
      // While the async preference read is in flight, don't redirect yet
      // — avoids a flash to /onboarding for returning users on cold start.
      final bool? complete = onboardingComplete.valueOrNull;
      if (complete == null) return null;

      final bool goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!complete && !goingToOnboarding) return AppRoutes.onboarding;
      if (complete && goingToOnboarding) return AppRoutes.home;
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: <RouteBase>[
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
    ],
  );
});

/// Bridges Riverpod's [onboardingCompleteProvider] into a [Listenable] so
/// GoRouter re-evaluates its `redirect` callback the moment the async
/// onboarding-complete flag finishes loading, instead of only on
/// navigation events.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    _sub = ref.listen<AsyncValue<bool>>(
      onboardingCompleteProvider,
      (AsyncValue<bool>? previous, AsyncValue<bool> next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<bool>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
