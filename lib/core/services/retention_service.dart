import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_reward.dart';
import '../models/weekly_challenge.dart';
import '../models/xp_level.dart';

/// Manages daily rewards, weekly challenges, and login tracking
class RetentionService {
  static const String _dailyRewardKey = 'daily_reward_state';
  static const String _weeklyChallengeKey = 'weekly_challenge';
  static const String _totalXpKey = 'total_xp';
  static const String _dailyChallengesCompletedKey = 'daily_challenges_completed';
  static const String _totalCoinsEarnedKey = 'total_coins_earned';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── XP System ──
  int get totalXp => _prefs.getInt(_totalXpKey) ?? 0;
  int get playerLevel => XpLevel.levelForXp(totalXp);

  Future<int> addXp(int amount) async {
    final oldLevel = playerLevel;
    final newXp = totalXp + amount;
    await _prefs.setInt(_totalXpKey, newXp);
    final newLevel = XpLevel.levelForXp(newXp);
    // Return levels gained (0 if no level up)
    return newLevel - oldLevel;
  }

  // ── Daily Rewards ──
  Future<DailyRewardState> loadDailyRewardState() async {
    final raw = _prefs.getString(_dailyRewardKey);
    if (raw == null) return const DailyRewardState();
    return DailyRewardState.fromJson(jsonDecode(raw));
  }

  Future<void> saveDailyRewardState(DailyRewardState state) async {
    await _prefs.setString(_dailyRewardKey, jsonEncode(state.toJson()));
  }

  /// Check if daily reward can be claimed, update state
  Future<DailyRewardClaimResult> claimDailyReward() async {
    final state = await loadDailyRewardState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    if (state.lastClaimDate == today) {
      return DailyRewardClaimResult(
        success: false,
        reward: null,
        newState: state,
      );
    }

    // Calculate consecutive days
    int newConsecutive;
    if (state.lastClaimDate == yesterday) {
      newConsecutive = state.consecutiveDays + 1;
    } else {
      newConsecutive = 1; // Reset streak
    }

    final reward = DailyRewardCalendar.getReward(newConsecutive);
    final newState = DailyRewardState(
      lastClaimDate: today,
      consecutiveDays: newConsecutive,
      claimedToday: true,
    );

    await saveDailyRewardState(newState);
    return DailyRewardClaimResult(
      success: true,
      reward: reward,
      newState: newState,
    );
  }

  bool canClaimToday() {
    final raw = _prefs.getString(_dailyRewardKey);
    if (raw == null) return true;
    final state = DailyRewardState.fromJson(jsonDecode(raw));
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return state.lastClaimDate != today;
  }

  // ── Weekly Challenge ──
  String get currentWeekId {
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays +
                DateTime(now.year, 1, 1).weekday - 1) ~/
            7) +
        1;
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  Future<WeeklyChallenge> loadWeeklyChallenge() async {
    final weekId = currentWeekId;
    final raw = _prefs.getString('${_weeklyChallengeKey}_$weekId');
    if (raw == null) {
      // Generate new challenge for this week
      final challenge = WeeklyChallenge.generate(weekId);
      await saveWeeklyChallenge(challenge);
      return challenge;
    }
    return WeeklyChallenge.fromJson(jsonDecode(raw));
  }

  Future<void> saveWeeklyChallenge(WeeklyChallenge challenge) async {
    await _prefs.setString(
      '${_weeklyChallengeKey}_${challenge.weekId}',
      jsonEncode(challenge.toJson()),
    );
  }

  Future<WeeklyChallenge> updateWeeklyProgress({
    WeeklyTaskType? taskType,
    String? gameId,
    int increment = 1,
  }) async {
    final challenge = await loadWeeklyChallenge();
    final updatedTasks = challenge.tasks.map((task) {
      if (taskType != null && task.type == taskType) {
        if (task.gameId != null && gameId != null && task.gameId != gameId) {
          return task;
        }
        return task.copyWith(current: task.current + increment);
      }
      return task;
    }).toList();

    final updated = WeeklyChallenge(
      weekId: challenge.weekId,
      tasks: updatedTasks,
      totalXpReward: challenge.totalXpReward,
      totalCoinReward: challenge.totalCoinReward,
    );
    await saveWeeklyChallenge(updated);
    return updated;
  }

  // ── Counters ──
  int get dailyChallengesCompleted =>
      _prefs.getInt(_dailyChallengesCompletedKey) ?? 0;

  Future<void> incrementDailyChallenges() async {
    await _prefs.setInt(
      _dailyChallengesCompletedKey,
      dailyChallengesCompleted + 1,
    );
  }

  int get totalCoinsEarned => _prefs.getInt(_totalCoinsEarnedKey) ?? 0;

  Future<void> addToTotalCoinsEarned(int amount) async {
    await _prefs.setInt(_totalCoinsEarnedKey, totalCoinsEarned + amount);
  }
}

class DailyRewardClaimResult {
  final bool success;
  final DailyReward? reward;
  final DailyRewardState newState;

  const DailyRewardClaimResult({
    required this.success,
    required this.reward,
    required this.newState,
  });
}
