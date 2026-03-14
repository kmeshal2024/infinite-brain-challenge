import 'package:flutter/material.dart';
import '../../core/models/game_result.dart';
import '../../core/models/game_type.dart';
import '../../core/constants/app_constants.dart';

/// Base class for mini-game controllers.
/// Provides shared logic: timer, scoring, stars calculation, result building.
mixin MiniGameController {
  DateTime? _startTime;
  int _score = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;

  int get score => _score;
  int get correctAnswers => _correctAnswers;
  int get totalQuestions => _totalQuestions;

  void startTimer() {
    _startTime = DateTime.now();
  }

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  void addScore(int points) {
    _score += points;
  }

  void recordAnswer(bool isCorrect) {
    _totalQuestions++;
    if (isCorrect) _correctAnswers++;
  }

  void resetGameState() {
    _startTime = null;
    _score = 0;
    _correctAnswers = 0;
    _totalQuestions = 0;
  }

  /// Calculate stars based on accuracy
  int calculateStars(double accuracy) {
    if (accuracy >= 1.0) return 3;
    if (accuracy >= 0.7) return 2;
    if (accuracy >= 0.4) return 1;
    return 0;
  }

  /// Calculate coins earned
  int calculateCoins(int stars, bool isPerfect) {
    if (isPerfect) return GameConstants.coinsPerPerfectLevel;
    if (stars > 0) return GameConstants.coinsPerLevelComplete;
    return 0;
  }

  /// Build the game result
  GameResult buildResult({
    required GameType gameType,
    required String gameId,
    required int level,
    required bool isWin,
    Map<String, dynamic> extraData = const {},
  }) {
    final accuracy =
        _totalQuestions > 0 ? _correctAnswers / _totalQuestions : 0.0;
    final stars = isWin ? calculateStars(accuracy) : 0;
    final isPerfect = accuracy >= 1.0 && isWin;
    final coins = calculateCoins(stars, isPerfect);

    return GameResult(
      gameType: gameType,
      gameId: gameId,
      level: level,
      isWin: isWin,
      score: _score,
      stars: stars,
      coinsEarned: coins,
      timeTaken: elapsed,
      isPerfect: isPerfect,
      correctAnswers: _correctAnswers,
      totalQuestions: _totalQuestions,
      extraData: extraData,
    );
  }
}

/// Difficulty scaling helper
class DifficultyScaler {
  /// Returns a difficulty value that scales with level.
  /// e.g., for pattern length: level 1 = 3, level 10 = 7, etc.
  static int scaleInt({
    required int level,
    required int baseValue,
    required int maxValue,
    double rate = 0.3,
  }) {
    final scaled = baseValue + (level * rate).floor();
    return scaled.clamp(baseValue, maxValue);
  }

  /// Returns a duration that decreases with difficulty
  static Duration scaleDuration({
    required int level,
    required int baseMs,
    required int minMs,
    double rate = 50,
  }) {
    final scaled = baseMs - (level * rate).floor();
    return Duration(milliseconds: scaled.clamp(minMs, baseMs));
  }
}
