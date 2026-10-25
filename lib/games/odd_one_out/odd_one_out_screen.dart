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

class OddOneOutScreen extends ConsumerStatefulWidget {
  final int level;
  const OddOneOutScreen({super.key, required this.level});

  @override
  ConsumerState<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends ConsumerState<OddOneOutScreen>
    with MiniGameController, SingleTickerProviderStateMixin {
  static const String gameId = 'odd_one_out';

  bool _started = false;
  int _currentRound = 0;
  late int _totalRounds;
  late int _gridCount;
  int _oddIndex = 0;
  int? _selectedIndex;
  bool _showResult = false;

  Color _baseColor = Colors.blue;
  Color _oddColor = Colors.red;
  double _baseRotation = 0;
  double _oddRotation = 0;
  double _baseSize = 1.0;
  double _oddSize = 1.0;
  IconData _baseShape = Icons.circle;
  IconData _oddShape = Icons.circle;

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
    _gridCount = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 4,
      maxValue: 16,
      rate: 0.6,
    );
    final sqRoot = sqrt(_gridCount).ceil();
    _gridCount = sqRoot * sqRoot;

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
    _oddIndex = rng.nextInt(_gridCount);
    _selectedIndex = null;
    _showResult = false;

    const shapes = [
      Icons.circle,
      Icons.square_rounded,
      Icons.change_history_rounded,
      Icons.hexagon_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];

    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.memoryColor,
      AppColors.logicColor,
      AppColors.patternColor,
      AppColors.puzzleColor,
    ];

    _baseShape = shapes[rng.nextInt(shapes.length)];
    _baseColor = colors[rng.nextInt(colors.length)];
    _baseRotation = 0;
    _baseSize = 1.0;

    if (widget.level <= 5) {
      final oddColors = colors.where((c) => c != _baseColor).toList();
      _oddColor = oddColors[rng.nextInt(oddColors.length)];
      _oddShape = _baseShape;
      _oddRotation = _baseRotation;
      _oddSize = _baseSize;
    } else if (widget.level <= 15) {
      if (rng.nextBool()) {
        _oddColor = HSLColor.fromColor(_baseColor)
            .withLightness(
              (HSLColor.fromColor(_baseColor).lightness + 0.15).clamp(0.0, 1.0),
            )
            .toColor();
        _oddShape = _baseShape;
      } else {
        final oddShapes = shapes.where((s) => s != _baseShape).toList();
        _oddShape = oddShapes[rng.nextInt(oddShapes.length)];
        _oddColor = _baseColor;
      }
      _oddRotation = _baseRotation;
      _oddSize = _baseSize;
    } else {
      final diffType = rng.nextInt(3);
      _oddColor = _baseColor;
      _oddShape = _baseShape;
      _oddRotation = _baseRotation;
      _oddSize = _baseSize;

      switch (diffType) {
        case 0:
          _oddSize = _baseSize * (rng.nextBool() ? 0.8 : 1.2);
          break;
        case 1:
          _oddRotation = (rng.nextInt(3) + 1) * 15.0 * pi / 180;
          break;
        case 2:
          _oddColor = HSLColor.fromColor(_baseColor)
              .withLightness(
                (HSLColor.fromColor(_baseColor).lightness + 0.08)
                    .clamp(0.0, 1.0),
              )
              .toColor();
          break;
      }
    }

    setState(() {});
  }

  void _selectCell(int index) {
    if (_showResult) return;

    final audio = ref.read(audioServiceProvider);
    final correct = index == _oddIndex;
    recordAnswer(correct);
    addScore(correct ? 15 : 0);

    if (correct) {
      audio.playCorrect();
    } else {
      audio.playWrong();
      _shakeController.forward(from: 0);
    }

    setState(() {
      _selectedIndex = index;
      _showResult = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _currentRound++;
      if (!correct || _currentRound >= _totalRounds) {
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
      gameType: GameType.oddOneOut,
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
              title: 'Odd One Out',
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
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.patternColor.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}',
                style: AppTypography.displaySmall)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Find the odd one in a grid of $_gridCount items',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
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
    final crossAxisCount = sqrt(_gridCount).ceil();

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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              'Round ${_currentRound + 1} of $_totalRounds',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Tap the different one!', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: _gridCount,
                    itemBuilder: (context, index) {
                      final isOdd = index == _oddIndex;
                      final isSelected = _selectedIndex == index;

                      Color color = isOdd ? _oddColor : _baseColor;
                      double rotation = isOdd ? _oddRotation : _baseRotation;
                      double size = isOdd ? _oddSize : _baseSize;
                      IconData shape = isOdd ? _oddShape : _baseShape;

                      Color borderColor = AppColors.surfaceElevated;
                      if (_showResult && isOdd) {
                        borderColor = AppColors.success;
                      } else if (_showResult && isSelected && !isOdd) {
                        borderColor = AppColors.error;
                      }

                      return GestureDetector(
                        onTap: () => _selectCell(index),
                        child: AnimatedContainer(
                          duration: AppDurations.normal,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(
                              color: borderColor,
                              width: _showResult &&
                                      (isOdd || (isSelected && !isOdd))
                                  ? 2
                                  : 0.5,
                            ),
                            boxShadow: _showResult && isOdd
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: rotation,
                              child: Transform.scale(
                                scale: size,
                                child: Icon(
                                  shape,
                                  color: color,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 30).ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 200.ms,
                          );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
