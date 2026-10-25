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

class QuickMathScreen extends ConsumerStatefulWidget {
  final int level;
  const QuickMathScreen({super.key, required this.level});

  @override
  ConsumerState<QuickMathScreen> createState() => _QuickMathScreenState();
}

class _QuickMathScreenState extends ConsumerState<QuickMathScreen>
    with MiniGameController, SingleTickerProviderStateMixin {
  static const String gameId = 'quick_math';

  bool _started = false;
  int _currentRound = 0;
  late int _totalRounds;
  String _equation = '';
  int _correctAnswer = 0;
  List<int> _choices = [];
  int? _selectedAnswer;
  bool _isCorrect = false;

  // Timer bar
  late int _timePerQuestionMs;
  Timer? _questionTimer;
  double _timeRemaining = 1.0;

  // Shake animation
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _totalRounds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 5,
      maxValue: 15,
      rate: 0.5,
    );
    _timePerQuestionMs = (8000 - (widget.level * 300)).clamp(3000, 8000);

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
    final difficulty = widget.level;

    int a, b, result;
    String op;

    if (difficulty <= 5) {
      // Simple addition/subtraction
      a = rng.nextInt(20) + 1;
      b = rng.nextInt(20) + 1;
      if (rng.nextBool()) {
        op = '+';
        result = a + b;
      } else {
        if (a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        op = '-';
        result = a - b;
      }
    } else if (difficulty <= 15) {
      // Add multiplication, larger numbers
      final opType = rng.nextInt(3);
      if (opType == 0) {
        a = rng.nextInt(50) + 10;
        b = rng.nextInt(50) + 10;
        op = '+';
        result = a + b;
      } else if (opType == 1) {
        a = rng.nextInt(50) + 10;
        b = rng.nextInt(30) + 1;
        if (a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        op = '-';
        result = a - b;
      } else {
        a = rng.nextInt(12) + 2;
        b = rng.nextInt(12) + 2;
        op = '\u00D7';
        result = a * b;
      }
    } else {
      // All operations including division, larger numbers
      final opType = rng.nextInt(4);
      if (opType == 0) {
        a = rng.nextInt(100) + 20;
        b = rng.nextInt(100) + 20;
        op = '+';
        result = a + b;
      } else if (opType == 1) {
        a = rng.nextInt(100) + 30;
        b = rng.nextInt(50) + 1;
        if (a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        op = '-';
        result = a - b;
      } else if (opType == 2) {
        a = rng.nextInt(15) + 2;
        b = rng.nextInt(15) + 2;
        op = '\u00D7';
        result = a * b;
      } else {
        // Division - ensure clean result
        b = rng.nextInt(12) + 2;
        result = rng.nextInt(12) + 1;
        a = b * result;
        op = '\u00F7';
      }
    }

    _equation = '$a $op $b = ?';
    _correctAnswer = result;

    // Generate wrong answers
    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final offset = (rng.nextInt(10) + 1) * (rng.nextBool() ? 1 : -1);
      final wrong = result + offset;
      if (wrong != result && wrong >= 0) {
        wrongAnswers.add(wrong);
      }
    }

    _choices = [result, ...wrongAnswers]..shuffle();
    _selectedAnswer = null;
    _timeRemaining = 1.0;

    setState(() {});
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    const tickMs = 50;
    _questionTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
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
    if (_selectedAnswer != null) return;
    final audio = ref.read(audioServiceProvider);
    audio.playWrong();
    recordAnswer(false);

    setState(() {
      _selectedAnswer = -1; // sentinel for time-up
      _isCorrect = false;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _currentRound++;
      if (_currentRound >= _totalRounds) {
        final accuracy = correctAnswers / totalQuestions;
        _finishGame(accuracy >= 0.4);
      } else {
        _generateRound();
      }
    });
  }

  void _selectAnswer(int answer) {
    if (_selectedAnswer != null) return;
    _questionTimer?.cancel();

    final audio = ref.read(audioServiceProvider);
    final correct = answer == _correctAnswer;
    recordAnswer(correct);

    // Bonus points for speed
    final speedBonus = (_timeRemaining * 10).round();
    addScore(correct ? 15 + speedBonus : 0);

    if (correct) {
      audio.playCorrect();
    } else {
      audio.playWrong();
      _shakeController.forward(from: 0);
    }

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _currentRound++;
      if (_currentRound >= _totalRounds) {
        final accuracy = correctAnswers / totalQuestions;
        _finishGame(accuracy >= 0.4);
      } else {
        _generateRound();
      }
    });
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
      gameType: GameType.quickMath,
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
              title: 'Quick Math',
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
                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mathColor.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.calculate_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}',
                style: AppTypography.displaySmall)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Solve $_totalRounds math problems before time runs out!',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Speed bonus for fast answers',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mathColor,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
              ),
              onTap: _start,
              width: 200,
            ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameplay() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) * 8 *
            (1 - _shakeController.value);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            // Round indicator
            Text(
              'Round ${_currentRound + 1} of $_totalRounds',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Timer bar
            ClipRRect(
              borderRadius: AppRadius.roundAll,
              child: LinearProgressIndicator(
                value: _timeRemaining.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(
                  _timeRemaining > 0.3 ? AppColors.mathColor : AppColors.error,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            // Equation
            Text(
              _equation,
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(duration: 200.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 300.ms,
                ),
            const SizedBox(height: AppSpacing.huge),
            // Choices
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: _choices.asMap().entries.map((entry) {
                final i = entry.key;
                final choice = entry.value;
                final isSelected = _selectedAnswer == choice;
                final isCorrectChoice = choice == _correctAnswer;
                final showResult = _selectedAnswer != null;

                Color bg;
                Color border;
                Color textColor;
                if (showResult && isCorrectChoice) {
                  bg = AppColors.success.withOpacity(0.2);
                  border = AppColors.success;
                  textColor = AppColors.success;
                } else if (showResult && isSelected && !_isCorrect) {
                  bg = AppColors.error.withOpacity(0.2);
                  border = AppColors.error;
                  textColor = AppColors.error;
                } else {
                  bg = AppColors.surfaceCard;
                  border = AppColors.surfaceElevated;
                  textColor = AppColors.textPrimary;
                }

                return GestureDetector(
                  onTap: () => _selectAnswer(choice),
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: border, width: 1.5),
                      boxShadow: showResult && isCorrectChoice
                          ? [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$choice',
                        style: AppTypography.headingLarge.copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 80).ms).scale(
                      begin: const Offset(0.9, 0.9),
                      duration: 200.ms,
                    );
              }).toList(),
            ),
            const Spacer(),
            // Speed indicator
            if (_selectedAnswer == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: _timeRemaining > 0.5
                        ? AppColors.mathColor
                        : _timeRemaining > 0.3
                            ? AppColors.warning
                            : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Speed bonus: +${(_timeRemaining * 10).round()}',
                    style: AppTypography.labelMedium.copyWith(
                      color: _timeRemaining > 0.5
                          ? AppColors.mathColor
                          : _timeRemaining > 0.3
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
