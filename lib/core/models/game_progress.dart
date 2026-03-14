import 'dart:convert';

/// Tracks progress for a single game mode
class GameProgress {
  final String gameId;
  final int highestLevelUnlocked;
  final Map<int, LevelResult> levelResults; // level number -> result
  final int totalStarsEarned;
  final int bestScore;

  const GameProgress({
    required this.gameId,
    this.highestLevelUnlocked = 1,
    this.levelResults = const {},
    this.totalStarsEarned = 0,
    this.bestScore = 0,
  });

  GameProgress copyWith({
    String? gameId,
    int? highestLevelUnlocked,
    Map<int, LevelResult>? levelResults,
    int? totalStarsEarned,
    int? bestScore,
  }) {
    return GameProgress(
      gameId: gameId ?? this.gameId,
      highestLevelUnlocked: highestLevelUnlocked ?? this.highestLevelUnlocked,
      levelResults: levelResults ?? this.levelResults,
      totalStarsEarned: totalStarsEarned ?? this.totalStarsEarned,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'highestLevelUnlocked': highestLevelUnlocked,
        'levelResults': levelResults.map(
          (k, v) => MapEntry(k.toString(), v.toJson()),
        ),
        'totalStarsEarned': totalStarsEarned,
        'bestScore': bestScore,
      };

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    final results = <int, LevelResult>{};
    if (json['levelResults'] != null) {
      (json['levelResults'] as Map<String, dynamic>).forEach((k, v) {
        results[int.parse(k)] = LevelResult.fromJson(v);
      });
    }
    return GameProgress(
      gameId: json['gameId'] ?? '',
      highestLevelUnlocked: json['highestLevelUnlocked'] ?? 1,
      levelResults: results,
      totalStarsEarned: json['totalStarsEarned'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
    );
  }

  String encode() => jsonEncode(toJson());
  static GameProgress decode(String source) =>
      GameProgress.fromJson(jsonDecode(source));

  int starsForLevel(int level) {
    return levelResults[level]?.stars ?? 0;
  }

  bool isLevelUnlocked(int level) => level <= highestLevelUnlocked;
  bool isLevelCompleted(int level) => levelResults.containsKey(level);
}

/// Result of a single level attempt
class LevelResult {
  final int level;
  final int stars; // 0-3
  final int score;
  final int coinsEarned;
  final Duration timeTaken;
  final bool isPerfect;
  final DateTime completedAt;

  const LevelResult({
    required this.level,
    required this.stars,
    required this.score,
    required this.coinsEarned,
    required this.timeTaken,
    this.isPerfect = false,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'stars': stars,
        'score': score,
        'coinsEarned': coinsEarned,
        'timeTakenMs': timeTaken.inMilliseconds,
        'isPerfect': isPerfect,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
        level: json['level'] ?? 0,
        stars: json['stars'] ?? 0,
        score: json['score'] ?? 0,
        coinsEarned: json['coinsEarned'] ?? 0,
        timeTaken: Duration(milliseconds: json['timeTakenMs'] ?? 0),
        isPerfect: json['isPerfect'] ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : DateTime.now(),
      );
}
