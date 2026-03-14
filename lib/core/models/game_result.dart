import 'game_type.dart';

/// Result passed from gameplay to result screen
class GameResult {
  final GameType gameType;
  final String gameId;
  final int level;
  final bool isWin;
  final int score;
  final int stars; // 0-3
  final int coinsEarned;
  final Duration timeTaken;
  final bool isPerfect;
  final int correctAnswers;
  final int totalQuestions;
  final Map<String, dynamic> extraData; // game-specific stats

  const GameResult({
    required this.gameType,
    required this.gameId,
    required this.level,
    required this.isWin,
    required this.score,
    required this.stars,
    required this.coinsEarned,
    required this.timeTaken,
    this.isPerfect = false,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.extraData = const {},
  });

  double get accuracy {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions;
  }
}

/// Daily challenge state
class DailyChallenge {
  final String date; // yyyy-MM-dd
  final List<DailyChallengeGame> games;
  final bool isCompleted;
  final int totalScore;
  final int totalCoinsEarned;

  const DailyChallenge({
    required this.date,
    required this.games,
    this.isCompleted = false,
    this.totalScore = 0,
    this.totalCoinsEarned = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'games': games.map((g) => g.toJson()).toList(),
        'isCompleted': isCompleted,
        'totalScore': totalScore,
        'totalCoinsEarned': totalCoinsEarned,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      date: json['date'] ?? '',
      games: (json['games'] as List<dynamic>?)
              ?.map((g) => DailyChallengeGame.fromJson(g))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] ?? false,
      totalScore: json['totalScore'] ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] ?? 0,
    );
  }
}

class DailyChallengeGame {
  final String gameId;
  final int level;
  final bool isCompleted;
  final int score;

  const DailyChallengeGame({
    required this.gameId,
    required this.level,
    this.isCompleted = false,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'level': level,
        'isCompleted': isCompleted,
        'score': score,
      };

  factory DailyChallengeGame.fromJson(Map<String, dynamic> json) {
    return DailyChallengeGame(
      gameId: json['gameId'] ?? '',
      level: json['level'] ?? 1,
      isCompleted: json['isCompleted'] ?? false,
      score: json['score'] ?? 0,
    );
  }
}
