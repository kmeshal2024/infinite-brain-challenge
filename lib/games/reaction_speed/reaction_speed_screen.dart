import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/game_type.dart';
import '../../core/models/game_result.dart';
import '../../core/models/game_progress.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/game_hud.dart';
import '../../core/widgets/game_button.dart';
import '../../features/game_shell/pause_dialog.dart';
import '../common/mini_game_controller.dart';

enum ReactionState { intro, waiting, ready, tapped, tooEarly, finished }

class ReactionSpeedScreen extends ConsumerStatefulWidget {
  final int level;
  const ReactionSpeedScreen({super.key, required this.level});

  @override
  ConsumerState<ReactionSpeedScreen> createState() =>
      _ReactionSpeedScreenState();
}

class _ReactionSpeedScreenState extends ConsumerState<ReactionSpeedScreen>
    with MiniGameController {
  static const String gameId = 'reaction_speed';

  ReactionState _state = ReactionState.intro;
  Timer? _delayTimer;
  DateTime? _signalTime;
  int _reactionMs = 0;
  int _currentRound = 0;
  late int _totalRounds;
  final List<int> _reactionTimes = [];

  @override
  void initState() {
    super.initState();
    _totalRounds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 3,
      maxValue: 5,
      rate: 0.15,
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    resetGameState();
    startTimer();
    _currentRound = 0;
    _reactionTimes.clear();
    _startRound();
  }

  void _startRound() {
    setState(() => _state = ReactionState.waiting);

    final rng = Random();
    final delay = GameConstants.reactionSpeedMinDelayMs +
        rng.nextInt(
          GameConstants.reactionSpeedMaxDelayMs -
              GameConstants.reactionSpeedMinDelayMs,
        );

    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _signalTime = DateTime.now();
      setState(() => _state = ReactionState.ready);
    });
  }

  void _onTap() {
    if (_state == ReactionState.waiting) {
      // Tapped too early
      _delayTimer?.cancel();
      setState(() => _state = ReactionState.tooEarly);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startRound();
      });
      return;
    }

    if (_state == ReactionState.ready && _signalTime != null) {
      _reactionMs = DateTime.now().difference(_signalTime!).inMilliseconds;
      _reactionTimes.add(_reactionMs);
      recordAnswer(true);

      // Score based on speed
      int points;
      if (_reactionMs <= GameConstants.reactionSpeedExcellentMs) {
        points = 30;
      } else if (_reactionMs <= GameConstants.reactionSpeedGoodMs) {
        points = 20;
      } else if (_reactionMs <= GameConstants.reactionSpeedOkMs) {
        points = 10;
      } else {
        points = 5;
      }
      addScore(points);

      setState(() => _state = ReactionState.tapped);

      _currentRound++;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (_currentRound >= _totalRounds) {
          _finishGame();
        } else {
          _startRound();
        }
      });
    }
  }

  void _finishGame() {
    setState(() => _state = ReactionState.finished);

    final avgReaction = _reactionTimes.isEmpty
        ? 999
        : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;

    // Calculate stars based on average reaction time
    int stars;
    if (avgReaction <= GameConstants.reactionSpeedExcellentMs) {
      stars = 3;
    } else if (avgReaction <= GameConstants.reactionSpeedGoodMs) {
      stars = 2;
    } else if (avgReaction <= GameConstants.reactionSpeedOkMs) {
      stars = 1;
    } else {
      stars = 0;
    }

    final isWin = stars > 0;
    final isPerfect = stars == 3;
    final coins = isPerfect
        ? GameConstants.coinsPerPerfectLevel
        : isWin
            ? GameConstants.coinsPerLevelComplete
            : 0;

    final result = GameResult(
      gameType: GameType.reactionSpeed,
      gameId: gameId,
      level: widget.level,
      isWin: isWin,
      score: score,
      stars: stars,
      coinsEarned: coins,
      timeTaken: elapsed,
      isPerfect: isPerfect,
      correctAnswers: _reactionTimes.length,
      totalQuestions: _totalRounds,
      extraData: {'avgReactionMs': avgReaction},
    );

    if (isWin) {
      ref.read(playerDataProvider.notifier).recordGameResult(result);
      ref.read(gameProgressProvider(gameId).notifier).recordLevelResult(
            LevelResult(
              level: widget.level,
              stars: result.stars,
              score: result.score,
              coinsEarned: result.coinsEarned,
              timeTaken: result.timeTaken,
              isPerfect: result.isPerfect,
              completedAt: DateTime.now(),
            ),
          );
      ref.read(playerDataProvider.notifier).updateStreak();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) context.go('/results', extra: result);
    });
  }

  void _handlePause() async {
    _delayTimer?.cancel();
    final action = await showPauseDialog(context);
    if (!mounted) return;
    switch (action) {
      case PauseAction.restart:
        _startGame();
        break;
      case PauseAction.quit:
        context.go('/games/$gameId/levels');
        break;
      default:
        if (_state == ReactionState.waiting) _startRound();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            GameHUD(
              title: 'Reaction Speed',
              level: widget.level,
              score: score,
              onPause: _state != ReactionState.intro ? _handlePause : null,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_state == ReactionState.intro) return _buildIntro();
    return _buildGameArea();
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFD44444)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.speedColor.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}',
                style: AppTypography.displaySmall),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tap the screen as fast as you can\nwhen the color changes to green!',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$_totalRounds rounds',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFD44444)],
              ),
              onTap: _startGame,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    Color bgColor;
    String statusText;
    String subText = '';

    switch (_state) {
      case ReactionState.waiting:
        bgColor = AppColors.accent;
        statusText = 'Wait for green...';
        subText = 'Round ${_currentRound + 1} of $_totalRounds';
        break;
      case ReactionState.ready:
        bgColor = AppColors.success;
        statusText = 'TAP NOW!';
        break;
      case ReactionState.tapped:
        bgColor = AppColors.primaryDark;
        statusText = '${_reactionMs}ms';
        subText = _getReactionRating(_reactionMs);
        break;
      case ReactionState.tooEarly:
        bgColor = AppColors.errorDark;
        statusText = 'Too early!';
        subText = 'Wait for the green signal';
        break;
      default:
        bgColor = AppColors.surface;
        statusText = '';
    }

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.xxlAll,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_state == ReactionState.ready)
                Icon(Icons.bolt_rounded, color: Colors.white, size: 64),
              if (_state == ReactionState.tapped)
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 48),
              if (_state == ReactionState.tooEarly)
                Icon(Icons.warning_rounded,
                    color: Colors.white, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                statusText,
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              if (subText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subText,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getReactionRating(int ms) {
    if (ms <= GameConstants.reactionSpeedExcellentMs) return '⚡ Lightning Fast!';
    if (ms <= GameConstants.reactionSpeedGoodMs) return '🔥 Great!';
    if (ms <= GameConstants.reactionSpeedOkMs) return '👍 Good';
    return '🐌 Keep practicing!';
  }
}
