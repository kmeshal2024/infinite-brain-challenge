import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/game_type.dart';
import '../../core/models/game_progress.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/game_hud.dart';
import '../../core/widgets/game_button.dart';
import '../../features/game_shell/pause_dialog.dart';
import '../common/mini_game_controller.dart';

enum ChimpGameState { intro, preview, input, success, failure }

/// Classic "Chimp Test" working-memory challenge:
/// numbers 1..N are placed on a 5×5 grid, shown briefly, then
/// hidden. The player must tap them in ascending order.
class ChimpTestScreen extends ConsumerStatefulWidget {
  final int level;

  const ChimpTestScreen({super.key, required this.level});

  @override
  ConsumerState<ChimpTestScreen> createState() => _ChimpTestScreenState();
}

class _ChimpTestScreenState extends ConsumerState<ChimpTestScreen>
    with MiniGameController, TickerProviderStateMixin {
  static const String gameId = 'chimp_test';
  static const int gridSize = 25; // 5x5
  static const int crossAxisCount = 5;

  ChimpGameState _gameState = ChimpGameState.intro;
  late int _numberCount;
  late int _previewMs;

  // position (cell index) -> displayed number (1..N)
  final Map<int, int> _placements = {};
  int _nextExpected = 1;

  int _lastTappedCell = -1;
  bool _lastTapCorrect = false;
  bool _showingFeedback = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _feedbackController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();

    _numberCount = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: GameConstants.chimpTestStartCount,
      maxValue: GameConstants.chimpTestMaxCount,
      rate: 0.35,
    );
    _previewMs = (GameConstants.chimpTestPreviewMs -
            (widget.level * 60).clamp(0, 1200))
        .clamp(900, GameConstants.chimpTestPreviewMs);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _pulseController.dispose();
    _feedbackController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startGame() {
    final audio = ref.read(audioServiceProvider);
    audio.playGameStart();

    resetGameState();
    startTimer();
    _generatePlacements();
    setState(() {
      _nextExpected = 1;
      _gameState = ChimpGameState.preview;
    });

    _previewTimer = Timer(Duration(milliseconds: _previewMs), () {
      if (!mounted) return;
      setState(() => _gameState = ChimpGameState.input);
    });
  }

  void _generatePlacements() {
    final random = Random();
    _placements.clear();
    final taken = <int>{};
    while (taken.length < _numberCount) {
      taken.add(random.nextInt(gridSize));
    }
    final cells = taken.toList()..shuffle(random);
    for (var i = 0; i < cells.length; i++) {
      _placements[cells[i]] = i + 1;
    }
  }

  void _onCellTap(int index) {
    if (_gameState != ChimpGameState.input) return;
    final number = _placements[index];
    if (number == null) return;

    final audio = ref.read(audioServiceProvider);
    final isCorrect = number == _nextExpected;

    setState(() {
      _lastTappedCell = index;
      _lastTapCorrect = isCorrect;
      _showingFeedback = true;
    });
    recordAnswer(isCorrect);

    if (isCorrect) {
      audio.playCorrect();
      addScore(10 + widget.level);
      _nextExpected++;
      _feedbackController.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() => _showingFeedback = false);
      });

      if (_nextExpected > _numberCount) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          audio.playSuccess();
          setState(() => _gameState = ChimpGameState.success);
          _submitResult(true);
        });
      }
    } else {
      audio.playWrong();
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        audio.playFail();
        setState(() => _gameState = ChimpGameState.failure);
        _submitResult(false);
      });
    }
  }

  void _submitResult(bool isWin) {
    final result = buildResult(
      gameType: GameType.chimpTest,
      gameId: gameId,
      level: widget.level,
      isWin: isWin,
      extraData: {
        'numberCount': _numberCount,
        'reached': _nextExpected - 1,
      },
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

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.go('/results', extra: result);
      }
    });
  }

  void _handlePause() async {
    _previewTimer?.cancel();
    final action = await showPauseDialog(context);
    if (!mounted) return;
    switch (action) {
      case PauseAction.resume:
        if (_gameState == ChimpGameState.preview) {
          _previewTimer = Timer(Duration(milliseconds: _previewMs), () {
            if (!mounted) return;
            setState(() => _gameState = ChimpGameState.input);
          });
        }
        break;
      case PauseAction.restart:
        _startGame();
        break;
      case PauseAction.quit:
        context.go('/games/$gameId/levels');
        break;
      default:
        break;
    }
  }

  void _useHint() {
    if (_gameState != ChimpGameState.input) return;
    if (_nextExpected > _numberCount) return;
    ref.read(playerDataProvider.notifier).useHint();
    final target =
        _placements.entries.firstWhere((e) => e.value == _nextExpected).key;
    setState(() {
      _lastTappedCell = target;
      _lastTapCorrect = true;
      _showingFeedback = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _showingFeedback = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerDataProvider);
    final gameInfo = GameInfo.getByType(GameType.chimpTest);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            GameHUD(
              title: gameInfo.name,
              level: widget.level,
              score: score,
              hints: player.hints,
              onPause: _handlePause,
              onHint: player.hints > 0 ? _useHint : null,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_gameState) {
      case ChimpGameState.intro:
        return _buildIntro();
      case ChimpGameState.preview:
      case ChimpGameState.input:
        return _buildPlay();
      case ChimpGameState.success:
        return _buildFeedback(true);
      case ChimpGameState.failure:
        return _buildFeedback(false);
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'Level ${widget.level}',
            style: AppTypography.displaySmall,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Memorize the positions of $_numberCount numbers',
            style: AppTypography.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Then tap them in order from 1 to $_numberCount',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.huge),
          GameButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            onTap: _startGame,
            width: 200,
          ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildPlay() {
    final isPreview = _gameState == ChimpGameState.preview;
    final progressRatio =
        isPreview ? 0.0 : (_nextExpected - 1) / _numberCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              isPreview ? 'Memorize...' : 'Tap $_nextExpected',
              key: ValueKey(_gameState.toString() + _nextExpected.toString()),
              style: AppTypography.headingMedium.copyWith(
                color:
                    isPreview ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.roundAll,
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF34D399)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isPreview
                ? 'Watch...'
                : '${_nextExpected - 1} / $_numberCount',
            style: AppTypography.gameTimer
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final shake = sin(_shakeAnimation.value * pi * 4) *
                      8 *
                      (1 - _shakeAnimation.value);
                  return Transform.translate(
                    offset: Offset(shake, 0),
                    child: child,
                  );
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildGrid(isPreview),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isPreview) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: gridSize,
      itemBuilder: (context, index) => _buildCell(index, isPreview),
    );
  }

  Widget _buildCell(int index, bool isPreview) {
    final number = _placements[index];
    final hasNumber = number != null;
    final isTakenAlready = hasNumber && number < _nextExpected;
    final hasFeedback = _showingFeedback && _lastTappedCell == index;

    Color bgColor;
    Color borderColor;

    if (!hasNumber) {
      bgColor = AppColors.surfaceCard.withOpacity(0.5);
      borderColor = AppColors.surfaceElevated;
    } else if (isPreview) {
      bgColor = const Color(0xFF34D399).withOpacity(0.15);
      borderColor = const Color(0xFF34D399);
    } else if (isTakenAlready) {
      bgColor = AppColors.success.withOpacity(0.25);
      borderColor = AppColors.success;
    } else if (hasFeedback) {
      bgColor = _lastTapCorrect
          ? AppColors.success.withOpacity(0.3)
          : AppColors.error.withOpacity(0.3);
      borderColor = _lastTapCorrect ? AppColors.success : AppColors.error;
    } else {
      bgColor = AppColors.surfaceCard;
      borderColor = AppColors.surfaceElevated;
    }

    final showNumber = hasNumber && (isPreview || isTakenAlready);

    return GestureDetector(
      onTap: _gameState == ChimpGameState.input && hasNumber && !isTakenAlready
          ? () => _onCellTap(index)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isPreview && hasNumber
              ? [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: showNumber
              ? Text(
                  '$number',
                  style: AppTypography.headingLarge.copyWith(
                    color: isTakenAlready
                        ? AppColors.success
                        : Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFeedback(bool isSuccess) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isSuccess
                  ? AppColors.successGradient
                  : AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isSuccess ? AppColors.success : AppColors.accent)
                      .withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .shimmer(
                duration: 1200.ms,
                color: Colors.white.withOpacity(0.2),
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isSuccess ? 'Perfect Memory!' : 'Lost Track',
            style: AppTypography.headingLarge,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSuccess
                ? 'All $_numberCount numbers in order!'
                : 'You reached ${_nextExpected - 1} of $_numberCount',
            style: AppTypography.bodyMedium,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
