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

class NumberSequenceScreen extends ConsumerStatefulWidget {
  final int level;
  const NumberSequenceScreen({super.key, required this.level});

  @override
  ConsumerState<NumberSequenceScreen> createState() =>
      _NumberSequenceScreenState();
}

class _NumberSequenceScreenState extends ConsumerState<NumberSequenceScreen>
    with MiniGameController, SingleTickerProviderStateMixin {
  static const String gameId = 'number_sequence';

  bool _started = false;
  List<int?> _sequence = [];
  int _missingIndex = 0;
  int _correctAnswer = 0;
  List<int> _choices = [];
  int? _selectedAnswer;
  bool _isCorrect = false;
  int _currentRound = 0;
  late int _totalRounds;

  // Shake animation
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _totalRounds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 3,
      maxValue: 8,
      rate: 0.3,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
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
    final seqLength = DifficultyScaler.scaleInt(
      level: difficulty,
      baseValue: 4,
      maxValue: 7,
      rate: 0.2,
    );

    List<int> fullSequence;
    if (difficulty <= 5) {
      final start = rng.nextInt(10) + 1;
      final step = rng.nextInt(4) + 1;
      fullSequence = List.generate(seqLength, (i) => start + step * i);
    } else if (difficulty <= 15) {
      if (rng.nextBool()) {
        final start = rng.nextInt(5) + 1;
        final multiplier = rng.nextInt(3) + 2;
        fullSequence = List.generate(seqLength, (i) => start * pow(multiplier, i).toInt());
      } else {
        final start = rng.nextInt(20) + 1;
        final step = rng.nextInt(6) + 2;
        fullSequence = List.generate(seqLength, (i) => start + step * i);
      }
    } else {
      final type = rng.nextInt(3);
      if (type == 0) {
        final offset = rng.nextInt(5);
        fullSequence = List.generate(seqLength, (i) => (i + offset + 1) * (i + offset + 1));
      } else if (type == 1) {
        int a = rng.nextInt(5) + 1;
        int b = rng.nextInt(5) + 1;
        fullSequence = [a, b];
        for (int i = 2; i < seqLength; i++) {
          fullSequence.add(fullSequence[i - 1] + fullSequence[i - 2]);
        }
      } else {
        final start = rng.nextInt(20) + 10;
        final step1 = rng.nextInt(5) + 2;
        final step2 = rng.nextInt(3) + 1;
        fullSequence = [start];
        for (int i = 1; i < seqLength; i++) {
          fullSequence.add(
            fullSequence.last + (i % 2 == 0 ? -step2 : step1),
          );
        }
      }
    }

    _missingIndex = 1 + rng.nextInt(seqLength - 2);
    _correctAnswer = fullSequence[_missingIndex];

    _sequence = fullSequence.map<int?>((e) => e).toList();
    _sequence[_missingIndex] = null;

    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final offset = (rng.nextInt(10) + 1) * (rng.nextBool() ? 1 : -1);
      final wrong = _correctAnswer + offset;
      if (wrong != _correctAnswer && wrong > 0) {
        wrongAnswers.add(wrong);
      }
    }

    _choices = [_correctAnswer, ...wrongAnswers]..shuffle();
    _selectedAnswer = null;

    setState(() {});
  }

  void _selectAnswer(int answer) {
    if (_selectedAnswer != null) return;

    final audio = ref.read(audioServiceProvider);
    final correct = answer == _correctAnswer;
    recordAnswer(correct);
    addScore(correct ? 20 : 0);

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

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _currentRound++;
      if (_currentRound >= _totalRounds || !correct) {
        _finishGame(correct && _currentRound >= _totalRounds);
      } else {
        _generateRound();
      }
    });
  }

  void _finishGame(bool isWin) {
    final audio = ref.read(audioServiceProvider);
    if (isWin) {
      audio.playSuccess();
    } else {
      audio.playFail();
    }

    final result = buildResult(
      gameType: GameType.numberSequence,
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
              title: 'Number Sequence',
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
                  colors: [Color(0xFF4CC9F0), Color(0xFF3AA8D0)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.logicColor.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.tag_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}',
                style: AppTypography.displaySmall)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Find the missing number in $_totalRounds sequences',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CC9F0), Color(0xFF3AA8D0)],
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
            Text(
              'Round ${_currentRound + 1} of $_totalRounds',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Find the missing number',
                style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: _sequence.asMap().entries.map((entry) {
                final i = entry.key;
                final num = entry.value;
                final isMissing = num == null;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isMissing
                        ? AppColors.logicColor.withOpacity(0.15)
                        : AppColors.surfaceCard,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                      color: isMissing
                          ? AppColors.logicColor
                          : AppColors.surfaceElevated,
                      width: isMissing ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isMissing
                        ? const Icon(Icons.help_outline_rounded,
                            color: AppColors.logicColor, size: 24)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.1, 1.1),
                              duration: 800.ms,
                            )
                        : Text(
                            '$num',
                            style: AppTypography.headingMedium,
                          ),
                  ),
                ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.2);
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.huge),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: _choices.asMap().entries.map((entry) {
                final i = entry.key;
                final choice = entry.value;
                final isSelected = _selectedAnswer == choice;
                final isCorrectChoice = choice == _correctAnswer;
                final showResult = _selectedAnswer != null;

                Color bg;
                Color border;
                if (showResult && isCorrectChoice) {
                  bg = AppColors.success.withOpacity(0.2);
                  border = AppColors.success;
                } else if (showResult && isSelected && !_isCorrect) {
                  bg = AppColors.error.withOpacity(0.2);
                  border = AppColors.error;
                } else {
                  bg = AppColors.surfaceCard;
                  border = AppColors.surfaceElevated;
                }

                return GestureDetector(
                  onTap: () => _selectAnswer(choice),
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$choice',
                        style: AppTypography.headingLarge.copyWith(
                          color: showResult && isCorrectChoice
                              ? AppColors.success
                              : showResult && isSelected
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 100 + 300).ms).scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 300.ms,
                  );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
