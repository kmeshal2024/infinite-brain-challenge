import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptive difficulty system that tracks player performance
/// and adjusts game difficulty accordingly
class DifficultyService {
  static const String _performanceKey = 'player_performance';

  late SharedPreferences _prefs;
  Map<String, GamePerformance> _performance = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPerformance();
  }

  void _loadPerformance() {
    final raw = _prefs.getString(_performanceKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _performance = map.map(
        (k, v) => MapEntry(k, GamePerformance.fromJson(v)),
      );
    }
  }

  Future<void> _savePerformance() async {
    final map = _performance.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_performanceKey, jsonEncode(map));
  }

  /// Record a game attempt for performance tracking
  Future<void> recordAttempt({
    required String gameId,
    required int level,
    required bool isWin,
    required int stars,
    required double accuracy,
    required Duration timeTaken,
  }) async {
    final perf = _performance[gameId] ?? GamePerformance(gameId: gameId);

    final recentResults = List<bool>.from(perf.recentWins);
    recentResults.add(isWin);
    if (recentResults.length > 10) {
      recentResults.removeAt(0);
    }

    final recentAccuracy = List<double>.from(perf.recentAccuracies);
    recentAccuracy.add(accuracy);
    if (recentAccuracy.length > 10) {
      recentAccuracy.removeAt(0);
    }

    _performance[gameId] = perf.copyWith(
      totalAttempts: perf.totalAttempts + 1,
      totalWins: isWin ? perf.totalWins + 1 : perf.totalWins,
      recentWins: recentResults,
      recentAccuracies: recentAccuracy,
      lastLevel: level,
    );

    await _savePerformance();
  }

  /// Get difficulty modifier for a game
  /// Returns a value between -2 (much easier) and +2 (much harder)
  int getDifficultyModifier(String gameId) {
    final perf = _performance[gameId];
    if (perf == null || perf.totalAttempts < 3) return 0;

    final recentWinRate = perf.recentWinRate;
    final recentAccuracy = perf.averageRecentAccuracy;

    // Player is crushing it → make harder
    if (recentWinRate >= 0.9 && recentAccuracy >= 0.9) return 2;
    if (recentWinRate >= 0.8 && recentAccuracy >= 0.8) return 1;

    // Player is struggling → make easier
    if (recentWinRate <= 0.2) return -2;
    if (recentWinRate <= 0.4) return -1;

    return 0; // Just right
  }

  /// Get scaled difficulty parameters for a specific game
  DifficultyParams getParams({
    required String gameId,
    required int level,
  }) {
    final modifier = getDifficultyModifier(gameId);

    switch (gameId) {
      case 'pattern_memory':
        return DifficultyParams(
          gridSize: _clamp(3 + (level ~/ 5) + (modifier > 0 ? 1 : 0), 3, 6),
          sequenceLength:
              _clamp(3 + (level * 0.3).floor() + modifier, 3, 12),
          showDurationMs:
              _clamp(800 - (level * 20) - (modifier * 50), 300, 1200),
        );

      case 'number_sequence':
        return DifficultyParams(
          choiceCount: _clamp(4 + (level > 15 ? 1 : 0) + modifier, 3, 6),
          roundCount: _clamp(3 + (level * 0.2).floor() + modifier, 3, 8),
        );

      case 'odd_one_out':
        final baseGrid = 4 + (level * 0.6).floor();
        final sqRoot = _sqrt(baseGrid + modifier);
        return DifficultyParams(
          gridSize: sqRoot * sqRoot,
          roundCount: _clamp(3 + (level * 0.3).floor() + modifier, 3, 8),
        );

      case 'reaction_speed':
        return DifficultyParams(
          roundCount: _clamp(3 + (level * 0.15).floor(), 3, 5),
          minDelayMs: _clamp(1500 - (modifier * 200), 1000, 2000),
          maxDelayMs: _clamp(5000 - (modifier * 500), 3000, 6000),
        );

      default:
        return const DifficultyParams();
    }
  }

  GamePerformance? getPerformance(String gameId) => _performance[gameId];

  int _clamp(int value, int min, int max) => value.clamp(min, max);
  int _sqrt(int value) {
    var s = 2;
    while (s * s < value) {
      s++;
    }
    return s;
  }
}

/// Performance tracking for a single game type
class GamePerformance {
  final String gameId;
  final int totalAttempts;
  final int totalWins;
  final List<bool> recentWins; // last 10
  final List<double> recentAccuracies; // last 10
  final int lastLevel;

  const GamePerformance({
    required this.gameId,
    this.totalAttempts = 0,
    this.totalWins = 0,
    this.recentWins = const [],
    this.recentAccuracies = const [],
    this.lastLevel = 0,
  });

  double get overallWinRate =>
      totalAttempts > 0 ? totalWins / totalAttempts : 0;

  double get recentWinRate {
    if (recentWins.isEmpty) return 0;
    return recentWins.where((w) => w).length / recentWins.length;
  }

  double get averageRecentAccuracy {
    if (recentAccuracies.isEmpty) return 0;
    return recentAccuracies.reduce((a, b) => a + b) / recentAccuracies.length;
  }

  GamePerformance copyWith({
    int? totalAttempts,
    int? totalWins,
    List<bool>? recentWins,
    List<double>? recentAccuracies,
    int? lastLevel,
  }) {
    return GamePerformance(
      gameId: gameId,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      totalWins: totalWins ?? this.totalWins,
      recentWins: recentWins ?? this.recentWins,
      recentAccuracies: recentAccuracies ?? this.recentAccuracies,
      lastLevel: lastLevel ?? this.lastLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'totalAttempts': totalAttempts,
        'totalWins': totalWins,
        'recentWins': recentWins,
        'recentAccuracies': recentAccuracies,
        'lastLevel': lastLevel,
      };

  factory GamePerformance.fromJson(Map<String, dynamic> json) {
    return GamePerformance(
      gameId: json['gameId'] ?? '',
      totalAttempts: json['totalAttempts'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      recentWins: (json['recentWins'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          [],
      recentAccuracies: (json['recentAccuracies'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      lastLevel: json['lastLevel'] ?? 0,
    );
  }
}

/// Difficulty parameters returned by the difficulty service
class DifficultyParams {
  final int gridSize;
  final int sequenceLength;
  final int showDurationMs;
  final int choiceCount;
  final int roundCount;
  final int minDelayMs;
  final int maxDelayMs;

  const DifficultyParams({
    this.gridSize = 3,
    this.sequenceLength = 3,
    this.showDurationMs = 800,
    this.choiceCount = 4,
    this.roundCount = 3,
    this.minDelayMs = 1500,
    this.maxDelayMs = 5000,
  });
}
