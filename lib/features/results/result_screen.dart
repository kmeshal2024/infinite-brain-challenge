import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/game_result.dart';
import '../../core/models/game_type.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/share_service.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_hud.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameResult result;

  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _starsController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    // Play sounds
    final audio = ref.read(audioServiceProvider);
    if (widget.result.isWin) {
      audio.playCoin();
    }

    // Trigger interstitial ad every 3 games
    ref.read(adServiceProvider).onGameComplete();

    // Track review eligibility + maybe prompt the user
    if (widget.result.isWin) {
      final reviewService = ref.read(reviewServiceProvider);
      reviewService.recordLevelComplete().then((_) {
        if (!mounted) return;
        if (reviewService.shouldPromptReview()) {
          // Delay so it doesn't collide with the win animation
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            reviewService.requestReview();
          });
        }
      });
    }

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _starsController.forward();
        if (widget.result.isWin && widget.result.stars >= 2) {
          _confettiController.forward();
        }
      }
    });

    // Play star sounds with delay
    if (widget.result.isWin) {
      for (int i = 0; i < widget.result.stars; i++) {
        Future.delayed(Duration(milliseconds: 600 + i * 250), () {
          if (mounted) audio.playStar();
        });
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final game = GameInfo.getByType(result.gameType);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti layer
              if (result.isWin && result.stars >= 2)
                AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiController.value,
                        color1: game.color,
                        color2: AppColors.gold,
                      ),
                      size: MediaQuery.of(context).size,
                    );
                  },
                ),
              // Main content
              FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      // Result icon
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: result.isWin
                                ? AppColors.successGradient
                                : AppColors.accentGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (result.isWin
                                        ? AppColors.success
                                        : AppColors.accent)
                                    .withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            result.isWin
                                ? Icons.emoji_events_rounded
                                : Icons.refresh_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      )
                          .animate()
                          .shimmer(
                            delay: 800.ms,
                            duration: 1500.ms,
                            color: Colors.white.withOpacity(0.3),
                          ),
                      const SizedBox(height: AppSpacing.xl),
                      // Title
                      Text(
                        result.isWin
                            ? (result.isPerfect ? 'Perfect!' : 'Level Complete!')
                            : 'Try Again',
                        style: AppTypography.displaySmall,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${game.name} - Level ${result.level}',
                        style: AppTypography.bodyMedium,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: AppSpacing.xxl),
                      // Stars
                      if (result.isWin) ...[
                        AnimatedBuilder(
                          animation: _starsController,
                          builder: (context, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final delay = i * 0.25;
                                final progress =
                                    ((_starsController.value - delay) / 0.5)
                                        .clamp(0.0, 1.0);
                                final isFilled = i < result.stars;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Transform.scale(
                                    scale: isFilled ? (0.5 + progress * 0.5) : 1.0,
                                    child: Opacity(
                                      opacity: isFilled ? progress : 0.3,
                                      child: Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: isFilled
                                            ? AppColors.gold
                                            : AppColors.textDisabled,
                                        size: 44,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Score
                      AnimatedScore(score: result.score),
                      Text(
                        'SCORE',
                        style: AppTypography.labelMedium.copyWith(
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: AppSpacing.lg),
                      // Stats row
                      _buildStatsRow(result),
                      // Share button
                      if (result.isWin) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _buildShareButton(result),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                      // Buttons
                      if (result.isWin) ...[
                        GameButton(
                          label: 'Next Level',
                          onTap: () {
                            ref.read(audioServiceProvider).playButton();
                            context.go(
                              '/games/${result.gameId}/play/${result.level + 1}',
                            );
                          },
                          width: double.infinity,
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      GameButton(
                        label: result.isWin ? 'Replay' : 'Try Again',
                        onTap: () {
                          ref.read(audioServiceProvider).playButton();
                          context.go(
                            '/games/${result.gameId}/play/${result.level}',
                          );
                        },
                        isOutlined: result.isWin,
                        color: result.isWin ? AppColors.primary : null,
                        gradient: result.isWin ? null : AppColors.primaryGradient,
                        width: double.infinity,
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.md),
                      GameButton(
                        label: 'Home',
                        onTap: () {
                          ref.read(audioServiceProvider).playButton();
                          context.go('/home');
                        },
                        isOutlined: true,
                        color: AppColors.textSecondary,
                        width: double.infinity,
                      ).animate().fadeIn(delay: 900.ms),
                      // Watch ad for coins
                      if (result.isWin) ...[
                        const SizedBox(height: AppSpacing.lg),
                        GestureDetector(
                          onTap: () async {
                            final adService = ref.read(adServiceProvider);
                            final rewarded = await adService.showRewardedAd();
                            if (rewarded && mounted) {
                              ref.read(playerDataProvider.notifier).addCoins(50);
                              ref.read(audioServiceProvider).playCoin();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded,
                                  color: AppColors.gold, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Watch ad for +50 coins',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1000.ms),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(GameResult result) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(
          icon: Icons.monetization_on_rounded,
          value: '+${result.coinsEarned}',
          color: AppColors.gold,
        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3),
        const SizedBox(width: AppSpacing.lg),
        _StatChip(
          icon: Icons.timer_rounded,
          value: _formatDuration(result.timeTaken),
          color: AppColors.logicColor,
        ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        if (result.totalQuestions > 0) ...[
          const SizedBox(width: AppSpacing.lg),
          _StatChip(
            icon: Icons.check_circle_rounded,
            value: '${result.correctAnswers}/${result.totalQuestions}',
            color: AppColors.success,
          ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),
        ],
      ],
    );
  }

  Widget _buildShareButton(GameResult result) {
    return GestureDetector(
      onTap: () {
        ref.read(audioServiceProvider).playButton();
        final shareText = ShareService.gameResultShareText(result);
        Clipboard.setData(ClipboardData(text: shareText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Score copied to clipboard! Share it with friends!',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.surfaceCard,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: AppRadius.roundAll,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Share Score',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.roundAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Confetti painter for celebration effect
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final Random _rng = Random(42);

  _ConfettiPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final colors = [
      color1,
      color2,
      AppColors.gold,
      AppColors.success,
      AppColors.primary,
      AppColors.accent,
    ];

    for (int i = 0; i < 40; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
            .withOpacity((1 - progress) * 0.8);

      final startX = _rng.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height * (0.3 + _rng.nextDouble() * 0.7);

      final x = startX + sin(progress * pi * 2 + i) * 30;
      final y = startY + (endY - startY) * progress;

      final w = 4 + _rng.nextDouble() * 6;
      final h = 3 + _rng.nextDouble() * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * pi * 2 * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) {
    return old.progress != progress;
  }
}
