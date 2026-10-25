import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/game_type.dart';
import '../../core/models/game_progress.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/game_hud.dart';
import '../../core/widgets/game_button.dart';
import '../../features/game_shell/pause_dialog.dart';
import '../common/mini_game_controller.dart';

/// Color Match — classic Stroop test.
/// A color name is shown painted in some ink color. Tap MATCH if the
/// word matches the ink color, DIFFERENT if it doesn't.
class ColorMatchScreen extends ConsumerStatefulWidget {
  final int level;
  const ColorMatchScreen({super.key, required this.level});

  @override
  ConsumerState<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends ConsumerState<ColorMatchScreen>
    with MiniGameController, SingleTickerProviderStateMixin {
  static const String gameId = 'color_match';

  static const List<_ColorOption> _colors = [
    _ColorOption('RED', Color(0xFFEF4444)),
    _ColorOption('BLUE', Color(0xFF3B82F6)),
    _ColorOption('GREEN', Color(0xFF22C55E)),
    _ColorOption('YELLOW', Color(0xFFFACC15)),
    _ColorOption('PURPLE', Color(0xFFA855F7)),
    _ColorOption('PINK', Color(0xFFEC4899)),
  ];

  bool _started = false;
  int _currentRound = 0;
  late int _totalRounds;
  late int _timePerQuestionMs;

  String _wordText = '';
  Color _inkColor = Colors.white;
  bool _trueMatch = false;
  bool? _userAnswer; // null = not answered, true/false = user's choice
  bool _isCorrect = false;

  Timer? _questionTimer;
  double _timeRemaining = 1.0;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _totalRounds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 8,
      maxValue: 20,
      rate: 0.6,
    );
    _timePerQuestionMs = (3500 - (widget.level * 80)).clamp(1500, 3500);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _start() {
    ref.read(audioServiceProvider).playGameStart();
    resetGameState();
    startTimer();
    _currentRound = 0;
    _started = true;
    _generateRound();
  }

  void _generateRound() {
    final rng = Random();
    final wordOpt = _colors[rng.nextInt(_colors.length)];
    // ~50/50 chance of true match
    _trueMatch = rng.nextBool();
    _wordText = wordOpt.name;
    if (_trueMatch) {
      _inkColor = wordOpt.color;
    } else {
      // Pick a different color
      final others =
          _colors.where((c) => c.name != wordOpt.name).toList()..shuffle(rng);
      _inkColor = others.first.color;
    }
    _userAnswer = null;
    _timeRemaining = 1.0;

    setState(() {});
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    const tickMs = 50;
    _questionTimer =
        Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining -= tickMs / _timePerQuestionMs;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        _timeUp();
      }
    });
  }

  void _timeUp() {
    if (_userAnswer != null) return;
    final audio = ref.read(audioServiceProvider);
    audio.playWrong();
    recordAnswer(false);
    setState(() {
      _userAnswer = !_trueMatch; // sentinel for wrong
      _isCorrect = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _nextOrFinish();
    });
  }

  void _answer(bool match) {
    if (_userAnswer != null) return;
    _questionTimer?.cancel();

    final audio = ref.read(audioServiceProvider);
    final correct = match == _trueMatch;
    recordAnswer(correct);

    final speedBonus = (_timeRemaining * 10).round();
    addScore(correct ? 10 + speedBonus : 0);

    if (correct) {
      audio.playCorrect();
    } else {
      audio.playWrong();
      _shakeController.forward(from: 0);
    }

    setState(() {
      _userAnswer = match;
      _isCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _nextOrFinish();
    });
  }

  void _nextOrFinish() {
    _currentRound++;
    if (_currentRound >= _totalRounds) {
      final accuracy = correctAnswers / totalQuestions;
      _finishGame(accuracy >= 0.5);
    } else {
      _generateRound();
    }
  }

  void _finishGame(bool isWin) {
    _questionTimer?.cancel();
    final audio = ref.read(audioServiceProvider);
    if (isWin) {
      audio.playSuccess();
    } else {
      audio.playFail();
    }

    final result = buildResult(
      gameType: GameType.colorMatch,
      gameId: gameId,
      level: widget.level,
      isWin: isWin,
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

    context.go('/results', extra: result);
  }

  void _handlePause() async {
    _questionTimer?.cancel();
    final action = await showPauseDialog(context);
    if (!mounted) return;
    switch (action) {
      case PauseAction.restart:
        _start();
        break;
      case PauseAction.quit:
        context.go('/games/$gameId/levels');
        break;
      default:
        _startQuestionTimer();
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
              title: 'Color Match',
              level: widget.level,
              score: score,
              hints: player.hints,
              onPause: _started ? _handlePause : null,
            ),
            Expanded(
              child: _started ? _buildGameplay() : _buildIntro(),
            ),
          ],
        ),
      ),
    );
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
                  colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDB2777).withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.palette_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}', style: AppTypography.displaySmall)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Does the WORD match the INK color?\nTap Match or Different.',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
              ),
              onTap: _start,
              width: 200,
            )
                .animate()
                .fadeIn(delay: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameplay() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) *
            8 *
            (1 - _shakeController.value);
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Text(
              'Round ${_currentRound + 1} of $_totalRounds',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: AppRadius.roundAll,
              child: LinearProgressIndicator(
                value: _timeRemaining.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(
                  _timeRemaining > 0.3 ? const Color(0xFFDB2777) : AppColors.error,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            Expanded(
              child: Center(
                child: Text(
                  _wordText,
                  style: AppTypography.displayLarge.copyWith(
                    color: _inkColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    fontSize: 64,
                  ),
                ).animate().fadeIn(duration: 200.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      duration: 300.ms,
                    ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnswerButton(
                  label: 'MATCH',
                  icon: Icons.check_rounded,
                  isCorrectOption: _trueMatch,
                  onTap: () => _answer(true),
                  color: AppColors.success,
                ),
                _buildAnswerButton(
                  label: 'DIFFERENT',
                  icon: Icons.close_rounded,
                  isCorrectOption: !_trueMatch,
                  onTap: () => _answer(false),
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required bool isCorrectOption,
    required VoidCallback onTap,
    required Color color,
  }) {
    final showResult = _userAnswer != null;
    final chosen = showResult &&
        ((label == 'MATCH' && _userAnswer == true) ||
            (label == 'DIFFERENT' && _userAnswer == false));

    Color bg;
    Color borderColor;
    if (showResult && isCorrectOption) {
      bg = AppColors.success.withOpacity(0.2);
      borderColor = AppColors.success;
    } else if (showResult && chosen && !_isCorrect) {
      bg = AppColors.error.withOpacity(0.2);
      borderColor = AppColors.error;
    } else {
      bg = AppColors.surfaceCard;
      borderColor = color.withOpacity(0.5);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: showResult && isCorrectOption
              ? [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(label,
                style: AppTypography.labelLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}
