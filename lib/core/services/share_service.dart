import '../models/game_result.dart';
import '../models/game_type.dart';

/// Generates share text and handles social sharing
/// Uses platform share sheet via method channels (or share_plus when added)
class ShareService {
  /// Generate share text for a game result
  static String gameResultShareText(GameResult result) {
    final game = GameInfo.getByType(result.gameType);
    final stars = '⭐' * result.stars;

    if (result.isPerfect) {
      return '🧠 I got a PERFECT score on ${game.name} Level ${result.level}! '
          '$stars\n'
          'Score: ${result.score} points\n\n'
          'Can you beat me? 🏆\n'
          '#InfiniteBrainChallenge #BrainTraining';
    }

    return '🧠 I scored ${result.score} on ${game.name} Level ${result.level}! '
        '$stars\n'
        'Can you beat my brain score? ⚡\n\n'
        '#InfiniteBrainChallenge #BrainTraining';
  }

  /// Generate share text for daily challenge
  static String dailyChallengeShareText(int totalScore) {
    return '🧠 I completed today\'s Daily Brain Challenge!\n'
        'Total Score: $totalScore points 🏆\n\n'
        'Think you can beat me? Take the challenge! ⚡\n'
        '#InfiniteBrainChallenge #DailyChallenge';
  }

  /// Generate "challenge a friend" text
  static String challengeFriendText({String? gameId, int? level}) {
    if (gameId != null && level != null) {
      final game = GameInfo.getById(gameId);
      return '🧠 I challenge you to beat ${game.name} Level $level!\n\n'
          'Download Infinite Brain Challenge and show me what you got! 💪\n'
          '#InfiniteBrainChallenge';
    }
    return '🧠 Challenge accepted? Train your brain with me!\n\n'
        'Download Infinite Brain Challenge — 4 addictive brain games! 💪\n'
        '#InfiniteBrainChallenge';
  }

  /// Generate share text for achievement unlock
  static String achievementShareText(String achievementName) {
    return '🏆 I just unlocked the "$achievementName" achievement '
        'in Infinite Brain Challenge!\n\n'
        'How many can you unlock? 🧠\n'
        '#InfiniteBrainChallenge #Achievement';
  }

  /// Generate weekly challenge share text
  static String weeklyCompleteShareText() {
    return '🏆 I completed this week\'s Brain Challenge!\n\n'
        'All weekly tasks done ✅\n'
        'Can you keep up? 🧠\n'
        '#InfiniteBrainChallenge #WeeklyChallenge';
  }
}
