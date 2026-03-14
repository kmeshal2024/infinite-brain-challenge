import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// Manages achievement tracking and unlocking
class AchievementService {
  static const String _progressKey = 'achievement_progress';

  late SharedPreferences _prefs;
  Map<String, AchievementProgress> _progressMap = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProgress();
  }

  void _loadProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _progressMap = map.map(
        (k, v) => MapEntry(k, AchievementProgress.fromJson(v)),
      );
    }
  }

  Future<void> _saveProgress() async {
    final map = _progressMap.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_progressKey, jsonEncode(map));
  }

  /// Get progress for a specific achievement
  AchievementProgress getProgress(String achievementId) {
    return _progressMap[achievementId] ??
        AchievementProgress(achievementId: achievementId);
  }

  /// Get all achievement progresses
  List<AchievementProgress> get allProgress {
    return Achievements.all.map((a) => getProgress(a.id)).toList();
  }

  /// Get unlocked achievements count
  int get unlockedCount =>
      _progressMap.values.where((p) => p.isUnlocked).length;

  /// Check and potentially unlock an achievement
  /// Returns the achievement if newly unlocked, null otherwise
  Future<Achievement?> checkAndUnlock(
    String achievementId, {
    int? setValue,
    int incrementBy = 0,
  }) async {
    final achievement = Achievements.all.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => throw ArgumentError('Unknown achievement: $achievementId'),
    );

    var progress = getProgress(achievementId);
    if (progress.isUnlocked) return null; // Already unlocked

    int newValue;
    if (setValue != null) {
      newValue = setValue;
    } else {
      newValue = progress.currentValue + incrementBy;
    }

    progress = progress.copyWith(currentValue: newValue);

    if (newValue >= achievement.target && !progress.isUnlocked) {
      progress = progress.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      _progressMap[achievementId] = progress;
      await _saveProgress();
      return achievement; // Newly unlocked!
    }

    _progressMap[achievementId] = progress;
    await _saveProgress();
    return null;
  }

  /// Batch check multiple achievements after a game event
  Future<List<Achievement>> checkAfterGameComplete({
    required int totalGamesWon,
    required int totalStars,
    required int currentStreak,
    required int playerLevel,
    required int totalCoinsEarned,
    required int dailyChallengesCompleted,
    required Set<String> gamesPlayedAtLeastOnce,
    String? perfectGameId,
    bool isSpeedDemon = false,
  }) async {
    final unlocked = <Achievement>[];

    // Gameplay achievements
    Achievement? a;
    a = await checkAndUnlock('first_win', setValue: totalGamesWon);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('ten_wins', setValue: totalGamesWon);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('fifty_wins', setValue: totalGamesWon);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('hundred_wins', setValue: totalGamesWon);
    if (a != null) unlocked.add(a);

    // Perfect scores
    if (perfectGameId == 'pattern_memory') {
      a = await checkAndUnlock('perfect_memory', setValue: 1);
      if (a != null) unlocked.add(a);
    }
    if (perfectGameId == 'number_sequence') {
      a = await checkAndUnlock('perfect_logic', setValue: 1);
      if (a != null) unlocked.add(a);
    }
    if (perfectGameId == 'odd_one_out') {
      a = await checkAndUnlock('perfect_spotter', setValue: 1);
      if (a != null) unlocked.add(a);
    }
    if (isSpeedDemon) {
      a = await checkAndUnlock('speed_demon', setValue: 1);
      if (a != null) unlocked.add(a);
    }

    // Collection
    a = await checkAndUnlock('coins_100', setValue: totalCoinsEarned);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('coins_1000', setValue: totalCoinsEarned);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('stars_50', setValue: totalStars);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('stars_200', setValue: totalStars);
    if (a != null) unlocked.add(a);

    // Streaks
    a = await checkAndUnlock('streak_3', setValue: currentStreak);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('streak_7', setValue: currentStreak);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('streak_30', setValue: currentStreak);
    if (a != null) unlocked.add(a);

    // Special
    a = await checkAndUnlock('daily_5', setValue: dailyChallengesCompleted);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('all_games',
        setValue: gamesPlayedAtLeastOnce.length);
    if (a != null) unlocked.add(a);
    a = await checkAndUnlock('level_10', setValue: playerLevel);
    if (a != null) unlocked.add(a);

    return unlocked;
  }
}
