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

/// Math 24 — combine 4 numbers with + − × ÷ to reach exactly 24.
/// Tap number → tap operator → tap another number to combine.
/// The two operands are replaced by the result. Reach 24 with one number left.
class MathPuzzle24Screen extends ConsumerStatefulWidget {
  final int level;
  const MathPuzzle24Screen({super.key, required this.level});

  @override
  ConsumerState<MathPuzzle24Screen> createState() =>
      _MathPuzzle24ScreenState();
}

class _MathPuzzle24ScreenState extends ConsumerState<MathPuzzle24Screen>
    with MiniGameController {
  static const String gameId = 'math_puzzle_24';
  static const double target = 24.0;

  // Pre-curated solvable puzzles (each set has at least one way to make 24).
  static const List<List<int>> _easyPuzzles = [
    [2, 3, 4, 6], [1, 2, 3, 4], [2, 4, 4, 6], [3, 3, 4, 8],
    [4, 4, 4, 4], [3, 4, 5, 6], [2, 2, 6, 8], [1, 4, 5, 6],
    [2, 3, 5, 8], [2, 6, 6, 6], [1, 6, 6, 8], [4, 5, 6, 6],
  ];
  static const List<List<int>> _medPuzzles = [
    [1, 3, 4, 6], [2, 5, 5, 10], [3, 7, 7, 7], [1, 5, 11, 11],
    [3, 8, 8, 10], [1, 2, 7, 7], [1, 1, 4, 6], [4, 6, 7, 9],
    [2, 3, 10, 10], [1, 4, 9, 9], [5, 5, 5, 5],
  ];
  static const List<List<int>> _hardPuzzles = [
    [3, 3, 7, 7], [3, 3, 8, 8], [1, 5, 5, 5], [4, 7, 8, 8],
    [5, 6, 7, 9], [4, 4, 7, 7], [1, 1, 11, 11], [6, 7, 8, 9],
    [3, 5, 7, 13],
  ];

  bool _started = false;
  bool _solved = false;
  bool _failed = false;
  late int _totalRounds;
  int _currentRound = 0;
  int _roundsSolved = 0;

  List<_Token> _numbers = [];
  int? _selectedIndex;
  String? _selectedOp;

  // Undo stack: each entry is the numbers list snapshot before a combine
  final List<List<_Token>> _history = [];
  late List<int> _currentPuzzle;

  // Countdown per puzzle
  Timer? _timer;
  late int _secondsPerPuzzle;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _totalRounds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 3,
      maxValue: 7,
      rate: 0.3,
    );
    _secondsPerPuzzle = (60 - (widget.level * 2)).clamp(30, 60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<int> _pickPuzzle() {
    final rng = Random();
    final lvl = widget.level;
    final pool = lvl <= 3
        ? _easyPuzzles
        : lvl <= 8
            ? _medPuzzles
            : _hardPuzzles;
    return [...pool[rng.nextInt(pool.length)]]..shuffle(rng);
  }

  void _start() {
    ref.read(audioServiceProvider).playGameStart();
    resetGameState();
    startTimer();
    _currentRound = 0;
    _roundsSolved = 0;
    _started = true;
    _newPuzzle();
  }

  void _newPuzzle() {
    _currentPuzzle = _pickPuzzle();
    _numbers = _currentPuzzle.map((n) => _Token(n.toDouble())).toList();
    _selectedIndex = null;
    _selectedOp = null;
    _history.clear();
    _solved = false;
    _failed = false;
    _secondsLeft = _secondsPerPuzzle;
    setState(() {});
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _timeUp();
      }
    });
  }

  void _timeUp() {
    if (_solved) return;
    _failed = true;
    recordAnswer(false);
    ref.read(audioServiceProvider).playWrong();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 700), _nextOrFinish);
  }

  void _nextOrFinish() {
    _currentRound++;
    if (_currentRound >= _totalRounds) {
      final accuracy = _roundsSolved / _totalRounds;
      _finishGame(accuracy >= 0.4);
    } else {
      _newPuzzle();
    }
  }

  void _onNumberTap(int index) {
    if (_solved || _failed) return;
    if (_selectedIndex == null) {
      setState(() => _selectedIndex = index);
      return;
    }
    if (_selectedIndex == index) {
      setState(() {
        _selectedIndex = null;
        _selectedOp = null;
      });
      return;
    }
    if (_selectedOp == null) {
      setState(() => _selectedIndex = index);
      return;
    }

    final a = _numbers[_selectedIndex!].value;
    final b = _numbers[index].value;
    double? result;
    switch (_selectedOp) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '\u00D7':
        result = a * b;
        break;
      case '\u00F7':
        if (b == 0) {
          ref.read(audioServiceProvider).playWrong();
          return;
        }
        result = a / b;
        break;
    }
    if (result == null) return;

    // Save history snapshot for undo
    _history.add(_numbers.map((t) => _Token(t.value)).toList());

    final combined = _Token(result);
    final newList = <_Token>[];
    for (var i = 0; i < _numbers.length; i++) {
      if (i == _selectedIndex || i == index) {
        if (i == _selectedIndex) newList.add(combined);
      } else {
        newList.add(_numbers[i]);
      }
    }
    _numbers = newList;
    _selectedIndex = null;
    _selectedOp = null;

    final audio = ref.read(audioServiceProvider);

    if (_numbers.length == 1) {
      if ((_numbers.first.value - target).abs() < 1e-9) {
        _solved = true;
        _roundsSolved++;
        recordAnswer(true);
        addScore(40 + _secondsLeft);
        audio.playSuccess();
        _timer?.cancel();
        setState(() {});
        Future.delayed(const Duration(milliseconds: 900), _nextOrFinish);
        return;
      } else {
        _failed = true;
        recordAnswer(false);
        audio.playWrong();
        _timer?.cancel();
        setState(() {});
        Future.delayed(const Duration(milliseconds: 700), _nextOrFinish);
        return;
      }
    }

    audio.playCorrect();
    setState(() {});
  }

  void _onOperatorTap(String op) {
    if (_solved || _failed) return;
    if (_selectedIndex == null) return;
    setState(() => _selectedOp = op);
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _numbers = _history.removeLast();
      _selectedIndex = null;
      _selectedOp = null;
    });
  }

  void _resetPuzzle() {
    setState(() {
      _numbers = _currentPuzzle.map((n) => _Token(n.toDouble())).toList();
      _selectedIndex = null;
      _selectedOp = null;
      _history.clear();
    });
  }

  void _finishGame(bool isWin) {
    _timer?.cancel();
    final audio = ref.read(audioServiceProvider);
    if (isWin) {
      audio.playSuccess();
    } else {
      audio.playFail();
    }

    final result = buildResult(
      gameType: GameType.mathPuzzle24,
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
    _timer?.cancel();
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
        _startTimer();
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
              title: 'Math 24',
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
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.extension_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}', style: AppTypography.displaySmall)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Use all 4 numbers with + − × ÷ to reach 24.\n$_totalRounds puzzles, $_secondsPerPuzzle seconds each.',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Puzzle ${_currentRound + 1} of $_totalRounds',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              Row(children: [
                Icon(Icons.timer_outlined,
                    size: 18,
                    color: _secondsLeft <= 10
                        ? AppColors.error
                        : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${_secondsLeft}s',
                  style: AppTypography.labelLarge.copyWith(
                    color: _secondsLeft <= 10
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Make 24',
            style: AppTypography.displayMedium.copyWith(
              color: const Color(0xFFFBBF24),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.center,
                children: _numbers.asMap().entries.map((e) {
                  final selected = _selectedIndex == e.key;
                  return _buildNumberTile(
                    token: e.value,
                    selected: selected,
                    onTap: () => _onNumberTap(e.key),
                    index: e.key,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _opButton('+'),
              _opButton('-'),
              _opButton('\u00D7'),
              _opButton('\u00F7'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _sideButton(Icons.undo_rounded, 'Undo', _undo,
                  enabled: _history.isNotEmpty),
              const SizedBox(width: AppSpacing.lg),
              _sideButton(Icons.refresh_rounded, 'Reset', _resetPuzzle,
                  enabled: _history.isNotEmpty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTile({
    required _Token token,
    required bool selected,
    required VoidCallback onTap,
    required int index,
  }) {
    final display = _formatValue(token.value);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                )
              : null,
          color: selected ? null : AppColors.surfaceCard,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected
                ? const Color(0xFFFBBF24)
                : AppColors.surfaceElevated,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            display,
            style: AppTypography.headingLarge.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _opButton(String op) {
    final selected = _selectedOp == op;
    return GestureDetector(
      onTap: _selectedIndex == null ? null : () => _onOperatorTap(op),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFBBF24).withOpacity(0.25)
              : AppColors.surfaceCard,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected
                ? const Color(0xFFFBBF24)
                : AppColors.surfaceElevated,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            op,
            style: AppTypography.headingLarge.copyWith(
              color: selected
                  ? const Color(0xFFFBBF24)
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideButton(IconData icon, String label, VoidCallback onTap,
      {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.surfaceElevated),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double v) {
    if ((v - v.round()).abs() < 1e-9) return v.round().toString();
    return v.toStringAsFixed(2);
  }
}

class _Token {
  final double value;
  _Token(this.value);
}
