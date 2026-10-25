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

/// Word Memory — memorize a short word list, then pick out the words
/// you saw from a larger pool of words mixed with decoys.
class WordMemoryScreen extends ConsumerStatefulWidget {
  final int level;
  const WordMemoryScreen({super.key, required this.level});

  @override
  ConsumerState<WordMemoryScreen> createState() => _WordMemoryScreenState();
}

class _WordMemoryScreenState extends ConsumerState<WordMemoryScreen>
    with MiniGameController {
  static const String gameId = 'word_memory';

  static const List<String> _wordBank = [
    'ocean', 'planet', 'castle', 'forest', 'lantern', 'piano', 'silver', 'winter',
    'garden', 'mirror', 'dragon', 'window', 'meadow', 'bridge', 'cherry', 'desert',
    'marble', 'pillow', 'rocket', 'tunnel', 'velvet', 'ember', 'breeze', 'harbor',
    'island', 'jungle', 'lemon', 'nomad', 'orbit', 'prism', 'quill', 'spark',
    'thread', 'vault', 'whisper', 'yellow', 'amber', 'basil', 'comet', 'dawn',
    'eagle', 'fossil', 'glacier', 'honey', 'ivory', 'knight', 'lilac', 'moss',
  ];

  bool _started = false;
  bool _inMemorizePhase = true;
  bool _finished = false;

  late List<String> _targetWords; // words to remember
  late List<String> _pool; // words on recall screen (targets + decoys)
  final Set<String> _selected = {};

  late int _wordsToRemember;
  late int _memorizeSeconds;
  Timer? _memorizeTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _wordsToRemember = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 4,
      maxValue: 10,
      rate: 0.4,
    );
    _memorizeSeconds = DifficultyScaler.scaleInt(
      level: widget.level,
      baseValue: 8,
      maxValue: 14,
      rate: 0.2,
    );
  }

  @override
  void dispose() {
    _memorizeTimer?.cancel();
    super.dispose();
  }

  void _start() {
    ref.read(audioServiceProvider).playGameStart();
    resetGameState();
    startTimer();

    final rng = Random();
    final shuffled = [..._wordBank]..shuffle(rng);
    _targetWords = shuffled.take(_wordsToRemember).toList();
    final decoyCount = (_wordsToRemember * 1.5).ceil().clamp(4, 12);
    final decoys = shuffled.skip(_wordsToRemember).take(decoyCount).toList();
    _pool = [..._targetWords, ...decoys]..shuffle(rng);
    _selected.clear();

    _started = true;
    _inMemorizePhase = true;
    _finished = false;
    _secondsLeft = _memorizeSeconds;

    setState(() {});
    _startMemorizeCountdown();
  }

  void _startMemorizeCountdown() {
    _memorizeTimer?.cancel();
    _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
        _startRecallPhase();
      }
    });
  }

  void _startRecallPhase() {
    setState(() {
      _inMemorizePhase = false;
    });
  }

  void _toggleSelection(String word) {
    if (_finished) return;
    setState(() {
      if (_selected.contains(word)) {
        _selected.remove(word);
      } else {
        _selected.add(word);
      }
    });
  }

  void _submit() {
    if (_finished) return;
    _finished = true;

    final audio = ref.read(audioServiceProvider);
    int correct = 0;
    for (final w in _targetWords) {
      final chosen = _selected.contains(w);
      recordAnswer(chosen);
      if (chosen) correct++;
    }
    // Penalize false positives by counting them as wrong answers
    final falsePositives = _selected.where((w) => !_targetWords.contains(w));
    for (final _ in falsePositives) {
      recordAnswer(false);
    }

    addScore(correct * 20 - falsePositives.length * 10);
    if (correct == _targetWords.length && falsePositives.isEmpty) {
      audio.playSuccess();
    } else if (correct >= (_targetWords.length * 0.6).ceil()) {
      audio.playCorrect();
    } else {
      audio.playFail();
    }

    final accuracy = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
    _finishGame(accuracy >= 0.5);
  }

  void _finishGame(bool isWin) {
    final result = buildResult(
      gameType: GameType.wordMemory,
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
    _memorizeTimer?.cancel();
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
        if (_inMemorizePhase) _startMemorizeCountdown();
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
              title: 'Word Memory',
              level: widget.level,
              score: score,
              hints: player.hints,
              onPause: _started ? _handlePause : null,
            ),
            Expanded(
              child: !_started
                  ? _buildIntro()
                  : _inMemorizePhase
                      ? _buildMemorize()
                      : _buildRecall(),
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
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Level ${widget.level}', style: AppTypography.displaySmall)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Memorize $_wordsToRemember words in $_memorizeSeconds seconds, then pick them out.',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.huge),
            GameButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
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

  Widget _buildMemorize() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            'Memorize these words',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$_secondsLeft',
            style: AppTypography.displayLarge.copyWith(
              color: _secondsLeft <= 3 ? AppColors.error : AppColors.textPrimary,
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
                children: _targetWords
                    .asMap()
                    .entries
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF60A5FA),
                                Color(0xFF2563EB),
                              ],
                            ),
                            borderRadius: AppRadius.lgAll,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            e.value,
                            style: AppTypography.headingMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (e.key * 80).ms)
                            .scale(begin: const Offset(0.8, 0.8)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecall() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            'Select the words you saw',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_selected.length}/$_wordsToRemember selected',
            style: AppTypography.bodyMedium.copyWith(
              color: _selected.length == _wordsToRemember
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: _pool.asMap().entries.map((e) {
                  final word = e.value;
                  final selected = _selected.contains(word);
                  return GestureDetector(
                    onTap: () => _toggleSelection(word),
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2563EB).withOpacity(0.25)
                            : AppColors.surfaceCard,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF60A5FA)
                              : AppColors.surfaceElevated,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        word,
                        style: AppTypography.bodyLarge.copyWith(
                          color: selected
                              ? const Color(0xFF60A5FA)
                              : AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (e.key * 30).ms);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GameButton(
            label: 'Submit',
            icon: Icons.check_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            ),
            onTap: _selected.isEmpty ? null : _submit,
            width: 240,
          ),
        ],
      ),
    );
  }
}
