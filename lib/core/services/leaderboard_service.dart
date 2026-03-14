import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Leaderboard service — prepared for Firebase integration.
/// Currently stores personal bests locally.
/// When Firebase is added, swap the implementation to Firestore.
class LeaderboardService {
  static const String _personalBestKey = 'personal_bests';
  static const String _dailyScoreKey = 'daily_leaderboard_score';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Personal Bests (local) ──

  Map<String, int> get personalBests {
    final raw = _prefs.getString(_personalBestKey);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw));
  }

  Future<bool> updatePersonalBest(String gameId, int level, int score) async {
    final bests = personalBests;
    final key = '${gameId}_level_$level';
    final currentBest = bests[key] ?? 0;

    if (score > currentBest) {
      bests[key] = score;
      await _prefs.setString(_personalBestKey, jsonEncode(bests));
      return true; // New personal best!
    }
    return false;
  }

  int getPersonalBest(String gameId, int level) {
    return personalBests['${gameId}_level_$level'] ?? 0;
  }

  int getGameBestScore(String gameId) {
    final bests = personalBests;
    int best = 0;
    for (final entry in bests.entries) {
      if (entry.key.startsWith('${gameId}_')) {
        if (entry.value > best) best = entry.value;
      }
    }
    return best;
  }

  // ── Daily Score Tracking (for future daily leaderboard) ──

  Future<void> recordDailyScore(String date, int score) async {
    await _prefs.setInt('${_dailyScoreKey}_$date', score);
  }

  int getDailyScore(String date) {
    return _prefs.getInt('${_dailyScoreKey}_$date') ?? 0;
  }

  // ── Firebase Hooks (implement when ready) ──

  /// Submit score to global leaderboard
  /// TODO: Implement with Firebase Firestore
  Future<void> submitToGlobalLeaderboard({
    required String gameId,
    required int score,
    required String playerName,
  }) async {
    // Firebase implementation:
    // await FirebaseFirestore.instance
    //     .collection('leaderboards')
    //     .doc(gameId)
    //     .collection('scores')
    //     .add({
    //   'playerName': playerName,
    //   'score': score,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
  }

  /// Fetch global leaderboard
  /// TODO: Implement with Firebase Firestore
  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({
    required String gameId,
    int limit = 50,
  }) async {
    // Firebase implementation:
    // final snapshot = await FirebaseFirestore.instance
    //     .collection('leaderboards')
    //     .doc(gameId)
    //     .collection('scores')
    //     .orderBy('score', descending: true)
    //     .limit(limit)
    //     .get();
    // return snapshot.docs.map((d) => LeaderboardEntry.fromFirestore(d)).toList();
    return []; // Placeholder
  }

  /// Fetch daily leaderboard
  /// TODO: Implement with Firebase Firestore
  Future<List<LeaderboardEntry>> fetchDailyLeaderboard({
    required String date,
    int limit = 50,
  }) async {
    return []; // Placeholder
  }

  /// Fetch weekly leaderboard
  /// TODO: Implement with Firebase Firestore
  Future<List<LeaderboardEntry>> fetchWeeklyLeaderboard({
    required String weekId,
    int limit = 50,
  }) async {
    return []; // Placeholder
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int score;
  final int rank;
  final DateTime timestamp;

  const LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.rank,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'score': score,
        'rank': rank,
        'timestamp': timestamp.toIso8601String(),
      };
}
