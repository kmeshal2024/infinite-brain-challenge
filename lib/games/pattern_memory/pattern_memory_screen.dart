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

enum PatternGameState { intro, showing, hiding, input, success, failure }

class PatternMemoryScreen extends ConsumerStatefulWidget {
  final int level;

  const PatternMemoryScreen({super.key, required this.level});

  @override
  ConsumerState<PatternMemoryScreen> createState() =>
      _PatternMemoryScreenState();
}

class _PatternMemoryScreenState extends ConsumerState<PatternMemoryScreen>
    with MiniGameController, TickerProviderStateMixin {
  static const int gridSize = 9; // 3x3
  static const String gameId = 'pattern_memory';

  PatternGameState _gameState = PatternGameState.intro;
  late int _sequenceLength;
  List<int> _sequence = [];
  List<int> _playerInput = [];
  int _currentShowIndex = 0;
  int _activeCell = -1;
  bool _showingFeedback = false;
  int _lastTappedCell = -1;
  bool _lastTapCorrect = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _feedbackController;

  // Shake animation for wrong answers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _showTimer;

  @override
  void initState() {
    super.initState();
    _sequenceLength = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: GameConstants.patternMemoryStartLength,
      maxValue: GameConstants.patternMemoryMaxLength,
      rate: 0.35,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    _showTimer?.cancel();
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
    _generateSequence();
    setState(() {
      _gameState = PatternGameState.showing;
      _playerInput = [];
      _currentShowIndex = 0;
    });
    _showSequence();
  }

  void _generateSequence() {
    final random = Random();
    _sequence = [];
    while (_sequence.length < _sequenceLength) {
      final cell = random.nextInt(gridSize);
      if (_sequence.isEmpty || _sequence.last != cell) {
        _sequence.add(cell);
      }
    }
  }

  void _showSequence() {
    if (_currentShowIndex >= _sequence.length) {
      setState(() {
        _activeCell = -1;
        _gameState = PatternGameState.hiding;
      });
      _showTimer = Timer(
        Duration(milliseconds: GameConstants.patternMemoryHideDurationMs),
        () {
          if (mounted) {
            setState(() => _gameState = PatternGameState.input);
          }
        },
      );
      return;
    }

    setState(() {
      _activeCell = _sequence[_currentShowIndex];
    });
    ref.read(audioServiceProvider).playTap();

    _showTimer = Timer(
      Duration(milliseconds: GameConstants.patternMemoryShowDurationMs),
      () {
        if (!mounted) return;
        setState(() => _activeCell = -1);
        _showTimer = Timer(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          _currentShowIndex++;
          _showSequence();
        });
      },
    );
  }

  void _onCellTap(int index) {
    if (_gameState != PatternGameState.input) return;

    final audio = ref.read(audioServiceProvider);
    final expectedIndex = _playerInput.length;
    final isCorrect = _sequence[expectedIndex] == index;

    setState(() {
      _playerInput.add(index);
      _lastTappedCell = index;
      _lastTapCorrect = isCorrect;
      _showingFeedback = true;
    });

    recordAnswer(isCorrect);

    if (isCorrect) {
      audio.playCorrect();
    } else {
      audio.playWrong();
      _shakeController.forward(from: 0);
    }

    _feedbackController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _showingFeedback = false);
    });

    if (!isCorrect) {
      addScore((_playerInput.length - 1) * 10);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          audio.playFail();
          setState(() => _gameState = PatternGameState.failure);
          _submitResult(false);
        }
      });
      return;
    }

    addScore(10);

    if (_playerInput.length == _sequence.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          audio.playSuccess();
          setState(() => _gameState = PatternGameState.success);
          _submitResult(true);
        }
      });
    }
  }

  void _submitResult(bool isWin) {
    final result = buildResult(
      gameType: GameType.patternMemory,
      gameId: gameId,
      level: widget.level,
      isWin: isWin,
      extraData: {
        'sequenceLength': _sequenceLength,
        'correctCells': correctAnswers,
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
    _showTimer?.cancel();
    final action = await showPauseDialog(context);
    if (!mounted) return;

    switch (action) {
      case PauseAction.resume:
        if (_gameState == PatternGameState.showing) {
          _showSequence();
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

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerDataProvider);
    final gameInfo = GameInfo.getByType(GameType.patternMemory);

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
            Expanded(
              child: _buildGameContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_gameState) {
      case PatternGameState.intro:
        return _buildIntroState();
      case PatternGameState.showing:
      case PatternGameState.hiding:
      case PatternGameState.input:
        return _buildPlayState();
      case PatternGameState.success:
        return _buildFeedbackOverlay(true);
      case PatternGameState.failure:
        return _buildFeedbackOverlay(false);
    }
  }

  Widget _buildIntroState() {
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
                  colors: [Color(0xFF7C6FFF), Color(0xFF5B4FDF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.memoryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_view_rounded,
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
            'Memorize a sequence of $_sequenceLength tiles',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Watch carefully, then repeat!',
            style: AppTypography.bodyMedium,
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

  Widget _buildPlayState() {
    final isInputPhase = _gameState == PatternGameState.input;
    final progressRatio = isInputPhase
        ? _playerInput.length / _sequence.length
        : _currentShowIndex / _sequence.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              _getStatusText(),
              key: ValueKey(_gameState),
              style: AppTypography.headingMedium.copyWith(
                color: isInputPhase
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.roundAll,
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                isInputPhase ? AppColors.primary : AppColors.memoryColor,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isInputPhase
                ? '${_playerInput.length} / ${_sequence.length}'
                : 'Watch...',
            style: AppTypography.gameTimer.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final shake = sin(_shakeAnimation.value * pi * 4) * 8 *
                      (1 - _shakeAnimation.value);
                  return Transform.translate(
                    offset: Offset(shake, 0),
                    child: child,
                  );
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildGrid(isInputPhase),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isInteractive) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: gridSize,
      itemBuilder: (context, index) {
        return _buildCell(index, isInteractive);
      },
    );
  }

  Widget _buildCell(int index, bool isInteractive) {
    final isActive = _activeCell == index;
    final hasFeedback = _showingFeedback && _lastTappedCell == index;

    Color bgColor;
    Color borderColor;

    if (isActive) {
      bgColor = AppColors.memoryColor;
      borderColor = AppColors.memoryColor;
    } else if (hasFeedback) {
      bgColor = _lastTapCorrect
          ? AppColors.success.withOpacity(0.3)
          : AppColors.error.withOpacity(0.3);
      borderColor = _lastTapCorrect ? AppColors.success : AppColors.error;
    } else {
      bgColor = AppColors.surfaceCard;
      borderColor = AppColors.surfaceElevated;
    }

    return GestureDetector(
      onTap: isInteractive ? () => _onCellTap(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.memoryColor.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : hasFeedback && _lastTapCorrect
                  ? [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
        ),
        child: Center(
          child: hasFeedback
              ? Icon(
                  _lastTapCorrect
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color: _lastTapCorrect ? AppColors.success : AppColors.error,
                  size: 32,
                ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 200.ms,
                    curve: Curves.elasticOut,
                  )
              : null,
        ),
      ),
    );
  }

  Widget _buildFeedbackOverlay(bool isSuccess) {
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
            isSuccess ? 'Excellent!' : 'Wrong Pattern',
            style: AppTypography.headingLarge,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSuccess
                ? 'You got all $_sequenceLength tiles correct!'
                : 'You got ${correctAnswers} of ${_sequence.length} correct',
            style: AppTypography.bodyMedium,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_gameState) {
      case PatternGameState.showing:
        return 'Watch the pattern...';
      case PatternGameState.hiding:
        return 'Get ready...';
      case PatternGameState.input:
        return 'Repeat the pattern!';
      default:
        return '';
    }
  }

  void _useHint() {
    if (_gameState != PatternGameState.input) return;
    final nextIndex = _playerInput.length;
    if (nextIndex < _sequence.length) {
      ref.read(playerDataProvider.notifier).useHint();
      setState(() => _activeCell = _sequence[nextIndex]);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _activeCell = -1);
      });
    }
  }
}
