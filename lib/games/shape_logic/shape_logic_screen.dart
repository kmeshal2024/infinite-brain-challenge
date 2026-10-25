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

/// Shape Logic: Complete the pattern by choosing the correct shape.
/// A sequence of shapes follows a rule (color rotation, shape rotation,
/// size progression, etc.) and the player picks what comes next.
class ShapeLogicScreen extends ConsumerStatefulWidget {
  final int level;
  const ShapeLogicScreen({super.key, required this.level});

  @override
  ConsumerState<ShapeLogicScreen> createState() => _ShapeLogicScreenState();
}

class _ShapeLogicScreenState extends ConsumerState<ShapeLogicScreen>
    with MiniGameController, SingleTickerProviderStateMixin {
  static const String gameId = 'shape_logic';

  bool _started = false;
  int _currentRound = 0;
  late int _totalRounds;

  // Current puzzle
  List<_ShapeItem> _sequence = [];
  _ShapeItem? _correctAnswer;
  List<_ShapeItem> _choices = [];
  int? _selectedIndex;
  bool _showResult = false;

  // Shake
  late AnimationController _shakeController;

  static const _allShapes = [
    Icons.circle,
    Icons.square_rounded,
    Icons.change_history_rounded,
    Icons.hexagon_rounded,
    Icons.star_rounded,
    Icons.diamond_rounded,
  ];

  static const _allColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    AppColors.memoryColor,
    AppColors.logicColor,
    AppColors.patternColor,
    AppColors.puzzleColor,
    AppColors.mathColor,
  ];

  static const _sizes = [0.6, 0.8, 1.0, 1.2, 1.4];

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
    _selectedIndex = null;
    _showResult = false;

    if (difficulty <= 5) {
      // Easy: repeating color pattern, same shape
      _generateColorPattern(rng);
    } else if (difficulty <= 15) {
      // Medium: shape rotation or color+shape pattern
      if (rng.nextBool()) {
        _generateShapePattern(rng);
      } else {
        _generateColorPattern(rng);
      }
    } else {
      // Hard: multi-property patterns (shape + color + size)
      final type = rng.nextInt(3);
      if (type == 0) {
        _generateShapePattern(rng);
      } else if (type == 1) {
        _generateSizePattern(rng);
      } else {
        _generateMultiPattern(rng);
      }
    }

    setState(() {});
  }

  void _generateColorPattern(Random rng) {
    // Cycle through N colors with same shape
    final shape = _allShapes[rng.nextInt(_allShapes.length)];
    final numColors = 2 + rng.nextInt(3); // 2-4 colors
    final colorPool = List<Color>.from(_allColors)..shuffle(rng);
    final colors = colorPool.take(numColors).toList();

    _sequence = List.generate(4, (i) => _ShapeItem(
      shape: shape,
      color: colors[i % numColors],
      size: 1.0,
    ));

    _correctAnswer = _ShapeItem(
      shape: shape,
      color: colors[4 % numColors],
      size: 1.0,
    );

    _generateChoices(rng, shape: true, color: false);
  }

  void _generateShapePattern(Random rng) {
    // Cycle through shapes with same color
    final color = _allColors[rng.nextInt(_allColors.length)];
    final numShapes = 2 + rng.nextInt(3);
    final shapePool = List<IconData>.from(_allShapes)..shuffle(rng);
    final shapes = shapePool.take(numShapes).toList();

    _sequence = List.generate(4, (i) => _ShapeItem(
      shape: shapes[i % numShapes],
      color: color,
      size: 1.0,
    ));

    _correctAnswer = _ShapeItem(
      shape: shapes[4 % numShapes],
      color: color,
      size: 1.0,
    );

    _generateChoices(rng, shape: false, color: true);
  }

  void _generateSizePattern(Random rng) {
    // Growing or shrinking pattern
    final shape = _allShapes[rng.nextInt(_allShapes.length)];
    final color = _allColors[rng.nextInt(_allColors.length)];
    final growing = rng.nextBool();

    _sequence = List.generate(4, (i) {
      final sizeIdx = growing ? i : (4 - i);
      return _ShapeItem(
        shape: shape,
        color: color,
        size: _sizes[sizeIdx.clamp(0, _sizes.length - 1)],
      );
    });

    final nextSizeIdx = growing ? 4 : 0;
    _correctAnswer = _ShapeItem(
      shape: shape,
      color: color,
      size: _sizes[nextSizeIdx.clamp(0, _sizes.length - 1)],
    );

    _generateChoices(rng, shape: true, color: true, sizeVary: true);
  }

  void _generateMultiPattern(Random rng) {
    // Shape changes each step, color stays
    final color = _allColors[rng.nextInt(_allColors.length)];
    final shapePool = List<IconData>.from(_allShapes)..shuffle(rng);
    final numShapes = 3;
    final shapes = shapePool.take(numShapes).toList();

    _sequence = List.generate(4, (i) => _ShapeItem(
      shape: shapes[i % numShapes],
      color: color,
      size: 1.0,
    ));

    _correctAnswer = _ShapeItem(
      shape: shapes[4 % numShapes],
      color: color,
      size: 1.0,
    );

    _generateChoices(rng, shape: false, color: false);
  }

  void _generateChoices(Random rng, {
    bool shape = true,
    bool color = true,
    bool sizeVary = false,
  }) {
    final wrongs = <_ShapeItem>[];
    int attempts = 0;

    while (wrongs.length < 3 && attempts < 50) {
      attempts++;
      final wrongShape = shape
          ? _correctAnswer!.shape
          : _allShapes[rng.nextInt(_allShapes.length)];
      final wrongColor = color
          ? _correctAnswer!.color
          : _allColors[rng.nextInt(_allColors.length)];
      final wrongSize = sizeVary
          ? _sizes[rng.nextInt(_sizes.length)]
          : _correctAnswer!.size;

      final wrong = _ShapeItem(
        shape: wrongShape,
        color: wrongColor,
        size: wrongSize,
      );

      if (wrong != _correctAnswer &&
          !wrongs.any((w) => w == wrong)) {
        wrongs.add(wrong);
      }
    }

    // Fallback if we couldn't generate enough wrongs
    while (wrongs.length < 3) {
      wrongs.add(_ShapeItem(
        shape: _allShapes[rng.nextInt(_allShapes.length)],
        color: _allColors[rng.nextInt(_allColors.length)],
        size: _sizes[rng.nextInt(_sizes.length)],
      ));
    }

    _choices = [_correctAnswer!, ...wrongs]..shuffle(rng);
  }

  void _selectChoice(int index) {
    if (_showResult) return;

    final audio = ref.read(audioServiceProvider);
    final correct = _choices[index] == _correctAnswer;
    recordAnswer(correct);
    addScore(correct ? 20 : 0);

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

    Future.delayed(const Duration(milliseconds: 700), () {
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
      gameType: GameType.shapeLogic,
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
              title: 'Shape Logic',
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
                  colors: [Color(0xFFE879F9), Color(0xFFC026D3)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.puzzleColor.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.category_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}',
                style: AppTypography.displaySmall)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Complete $_totalRounds shape patterns',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Find what comes next in the sequence!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.puzzleColor,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFE879F9), Color(0xFFC026D3)],
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
            const SizedBox(height: AppSpacing.lg),
            Text('What comes next?', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.xxl),
            // Sequence display
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withOpacity(0.5),
                borderRadius: AppRadius.xlAll,
                border: Border.all(
                  color: AppColors.surfaceElevated,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._sequence.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildShapeWidget(entry.value, size: 44),
                    ).animate().fadeIn(delay: (entry.key * 150).ms).scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 300.ms,
                          curve: Curves.elasticOut,
                        );
                  }),
                  // Question mark
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.puzzleColor.withOpacity(0.1),
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(
                          color: AppColors.puzzleColor,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: AppColors.puzzleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        duration: 800.ms,
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            // Choices
            Text(
              'Choose the next shape:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: _choices.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isSelected = _selectedIndex == i;
                final isCorrectChoice = item == _correctAnswer;

                Color borderColor = AppColors.surfaceElevated;
                Color bgColor = AppColors.surfaceCard;

                if (_showResult && isCorrectChoice) {
                  borderColor = AppColors.success;
                  bgColor = AppColors.success.withOpacity(0.1);
                } else if (_showResult && isSelected && !isCorrectChoice) {
                  borderColor = AppColors.error;
                  bgColor = AppColors.error.withOpacity(0.1);
                }

                return GestureDetector(
                  onTap: () => _selectChoice(i),
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(
                        color: borderColor,
                        width: _showResult && (isCorrectChoice || isSelected)
                            ? 2.5
                            : 1,
                      ),
                      boxShadow: _showResult && isCorrectChoice
                          ? [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _buildShapeWidget(item, size: 40),
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 100 + 500).ms).scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 250.ms,
                    );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeWidget(_ShapeItem item, {double size = 36}) {
    return Transform.scale(
      scale: item.size,
      child: Icon(
        item.shape,
        color: item.color,
        size: size,
      ),
    );
  }
}

class _ShapeItem {
  final IconData shape;
  final Color color;
  final double size;

  const _ShapeItem({
    required this.shape,
    required this.color,
    required this.size,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ShapeItem &&
        other.shape == shape &&
        other.color == color &&
        (other.size - size).abs() < 0.01;
  }

  @override
  int get hashCode => Object.hash(shape, color, size.toStringAsFixed(2));
}
