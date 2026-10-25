/// ─── GAME CONSTANTS ─────────────────────────────────────────────
class GameConstants {
  GameConstants._();

  // Rewards
  static const int coinsPerLevelComplete = 10;
  static const int coinsPerPerfectLevel = 25;
  static const int coinsPerDailyChallenge = 30;
  static const int coinsRewardedAd = 50;
  static const int starsPerLevel = 3;
  static const int hintCost = 20;

  // Starting values
  static const int startingCoins = 100;
  static const int startingHints = 3;

  // Pattern Memory
  static const int patternMemoryStartLength = 3;
  static const int patternMemoryMaxLength = 12;
  static const int patternMemoryGridSize = 9; // 3x3
  static const int patternMemoryShowDurationMs = 800;
  static const int patternMemoryHideDurationMs = 300;

  // Chimp Test (number-position working memory)
  static const int chimpTestStartCount = 4;
  static const int chimpTestMaxCount = 15;
  static const int chimpTestPreviewMs = 2500;

  // Number Sequence
  static const int numberSequenceChoiceCount = 4;
  static const int numberSequenceStartDifficulty = 1;

  // Odd One Out
  static const int oddOneOutGridMin = 4;
  static const int oddOneOutGridMax = 16;

  // Reaction Speed
  static const int reactionSpeedMinDelayMs = 1500;
  static const int reactionSpeedMaxDelayMs = 5000;
  static const int reactionSpeedExcellentMs = 200;
  static const int reactionSpeedGoodMs = 350;
  static const int reactionSpeedOkMs = 500;

  // Levels per game mode
  static const int levelsPerMode = 30;

  // Daily Challenge
  static const int dailyChallengeGameCount = 3;

  // Streak
  static const int streakBonusThreshold = 7;
  static const int streakBonusCoins = 100;
}

/// ─── AD CONSTANTS (placeholders — ads NOT active in v1.0) ───────
/// AdMob is NOT integrated for v1.0 launch. These are placeholder
/// test IDs and will NOT be called in production. Replace with real
/// IDs when integrating google_mobile_ads in a future release.
class AdConstants {
  AdConstants._();

  // PLACEHOLDER — ads are disabled for v1.0, no SDK integrated
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
}

/// ─── ROUTE NAMES ────────────────────────────────────────────────
class Routes {
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String gameSelection = '/games';
  static const String levelSelection = '/games/:gameId/levels';
  static const String gameplay = '/games/:gameId/play/:level';
  static const String results = '/results';
  static const String dailyChallenge = '/daily';
  static const String profile = '/profile';
  static const String shop = '/shop';
  static const String settings = '/settings';
}

/// ─── STORAGE KEYS ───────────────────────────────────────────────
class StorageKeys {
  StorageKeys._();

  static const String playerData = 'player_data';
  static const String gameProgress = 'game_progress';
  static const String settings = 'app_settings';
  static const String dailyChallenge = 'daily_challenge';
  static const String onboardingComplete = 'onboarding_complete';
  static const String lastSessionDate = 'last_session_date';
}

/// ─── ANALYTICS EVENTS ──────────────────────────────────────────
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String gameStarted = 'game_started';
  static const String gameCompleted = 'game_completed';
  static const String gameFailed = 'game_failed';
  static const String levelUnlocked = 'level_unlocked';
  static const String dailyChallengeStarted = 'daily_challenge_started';
  static const String dailyChallengeCompleted = 'daily_challenge_completed';
  static const String coinsEarned = 'coins_earned';
  static const String coinsSpent = 'coins_spent';
  static const String hintUsed = 'hint_used';
  static const String rewardedAdWatched = 'rewarded_ad_watched';
  static const String shopOpened = 'shop_opened';
  static const String streakUpdated = 'streak_updated';

  // Retention & engagement
  static const String xpEarned = 'xp_earned';
  static const String levelUp = 'level_up';
  static const String dailyRewardClaimed = 'daily_reward_claimed';
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String weeklyTaskCompleted = 'weekly_task_completed';
  static const String weeklyChallengeCompleted = 'weekly_challenge_completed';
  static const String shareScore = 'share_score';
  static const String challengeFriend = 'challenge_friend';
  static const String spinWheelUsed = 'spin_wheel_used';
  static const String reviewPrompted = 'review_prompted';
  static const String reviewCompleted = 'review_completed';
}

/// ─── ROUTE NAMES (NEW) ─────────────────────────────────────────
class NewRoutes {
  NewRoutes._();

  static const String dailyRewards = '/daily-rewards';
  static const String achievements = '/achievements';
  static const String weeklyChallenge = '/weekly-challenge';
}
