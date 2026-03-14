/// Analytics service - stub for MVP, ready for Firebase Analytics integration.
/// Replace implementation with Firebase when ready.
class AnalyticsService {
  Future<void> init() async {
    // Firebase Analytics init will go here
  }

  void logEvent(String name, [Map<String, dynamic>? params]) {
    // ignore: avoid_print
    print('[Analytics] $name ${params ?? ''}');
    // TODO: Replace with FirebaseAnalytics.instance.logEvent(...)
  }

  void logGameStarted(String gameId, int level) {
    logEvent('game_started', {'game_id': gameId, 'level': level});
  }

  void logGameCompleted(String gameId, int level, int score, int stars) {
    logEvent('game_completed', {
      'game_id': gameId,
      'level': level,
      'score': score,
      'stars': stars,
    });
  }

  void logGameFailed(String gameId, int level) {
    logEvent('game_failed', {'game_id': gameId, 'level': level});
  }

  void logCoinsEarned(int amount, String source) {
    logEvent('coins_earned', {'amount': amount, 'source': source});
  }

  void logAdWatched(String type) {
    logEvent('ad_watched', {'type': type});
  }

  void logScreenView(String screenName) {
    logEvent('screen_view', {'screen_name': screenName});
  }

  // ── Retention Events ──

  void logXpEarned(int amount, String source) {
    logEvent('xp_earned', {'amount': amount, 'source': source});
  }

  void logLevelUp(int newLevel, String title) {
    logEvent('level_up', {'new_level': newLevel, 'title': title});
  }

  void logDailyRewardClaimed(int day, int coins) {
    logEvent('daily_reward_claimed', {'day': day, 'coins': coins});
  }

  void logAchievementUnlocked(String achievementId) {
    logEvent('achievement_unlocked', {'achievement_id': achievementId});
  }

  void logWeeklyTaskCompleted(String taskType) {
    logEvent('weekly_task_completed', {'task_type': taskType});
  }

  void logWeeklyChallengeCompleted(String weekId) {
    logEvent('weekly_challenge_completed', {'week_id': weekId});
  }

  // ── Engagement Events ──

  void logShareScore(String gameId, int score) {
    logEvent('share_score', {'game_id': gameId, 'score': score});
  }

  void logChallengeFriend(String gameId) {
    logEvent('challenge_friend', {'game_id': gameId});
  }

  void logSpinWheel(String reward) {
    logEvent('spin_wheel_used', {'reward': reward});
  }

  void logStreakMilestone(int streak) {
    logEvent('streak_milestone', {'streak': streak});
  }

  void logReviewPrompted() {
    logEvent('review_prompted');
  }

  void logReviewCompleted() {
    logEvent('review_completed');
  }
}
