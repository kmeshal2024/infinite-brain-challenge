import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/models/game_result.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/game_selection/game_selection_screen.dart';
import '../features/level_selection/level_selection_screen.dart';
import '../features/results/result_screen.dart';
import '../features/daily_challenge/daily_challenge_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/daily_rewards/daily_rewards_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/weekly_challenge/weekly_challenge_screen.dart';
import '../games/pattern_memory/pattern_memory_screen.dart';
import '../games/number_sequence/number_sequence_screen.dart';
import '../games/odd_one_out/odd_one_out_screen.dart';
import '../games/reaction_speed/reaction_speed_screen.dart';
import '../games/quick_math/quick_math_screen.dart';
import '../games/shape_logic/shape_logic_screen.dart';
import '../games/word_memory/word_memory_screen.dart';
import '../games/color_match/color_match_screen.dart';
import '../games/math_puzzle_24/math_puzzle_24_screen.dart';
import '../games/chimp_test/chimp_test_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.home,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: Routes.gameSelection,
      builder: (context, state) => const GameSelectionScreen(),
    ),
    GoRoute(
      path: Routes.levelSelection,
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        return LevelSelectionScreen(gameId: gameId);
      },
    ),
    GoRoute(
      path: Routes.gameplay,
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final level = int.parse(state.pathParameters['level']!);
        return _buildGameScreen(gameId, level);
      },
    ),
    GoRoute(
      path: Routes.results,
      redirect: (context, state) {
        if (state.extra == null) return Routes.home;
        return null;
      },
      builder: (context, state) {
        final result = state.extra as GameResult;
        return ResultScreen(result: result);
      },
    ),
    GoRoute(
      path: Routes.dailyChallenge,
      builder: (context, state) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: Routes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: Routes.shop,
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: NewRoutes.dailyRewards,
      builder: (context, state) => const DailyRewardsScreen(),
    ),
    GoRoute(
      path: NewRoutes.achievements,
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: NewRoutes.weeklyChallenge,
      builder: (context, state) => const WeeklyChallengeScreen(),
    ),
  ],
);

Widget _buildGameScreen(String gameId, int level) {
  switch (gameId) {
    case 'pattern_memory':
      return PatternMemoryScreen(level: level);
    case 'number_sequence':
      return NumberSequenceScreen(level: level);
    case 'odd_one_out':
      return OddOneOutScreen(level: level);
    case 'reaction_speed':
      return ReactionSpeedScreen(level: level);
    case 'quick_math':
      return QuickMathScreen(level: level);
    case 'shape_logic':
      return ShapeLogicScreen(level: level);
    case 'word_memory':
      return WordMemoryScreen(level: level);
    case 'color_match':
      return ColorMatchScreen(level: level);
    case 'math_puzzle_24':
      return MathPuzzle24Screen(level: level);
    case 'chimp_test':
      return ChimpTestScreen(level: level);
    default:
      return PatternMemoryScreen(level: level);
  }
}
