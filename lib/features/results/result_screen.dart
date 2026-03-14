import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import '../../core/models/game_result.dart';
import '../../core/models/game_type.dart';
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
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starsController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starsController.dispose();
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
          child: FadeTransition(
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
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Title
                  Text(
                    result.isWin
                        ? (result.isPerfect ? 'Perfect!' : 'Level Complete!')
                        : 'Try Again',
                    style: AppTypography.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${game.name} - Level ${result.level}',
                    style: AppTypography.bodyMedium,
                  ),
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
                  ),
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
                        context.go(
                          '/games/${result.gameId}/play/${result.level + 1}',
                        );
                      },
                      width: double.infinity,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  GameButton(
                    label: result.isWin ? 'Replay' : 'Try Again',
                    onTap: () {
                      context.go(
                        '/games/${result.gameId}/play/${result.level}',
                      );
                    },
                    isOutlined: result.isWin,
                    color: result.isWin ? AppColors.primary : null,
                    gradient: result.isWin ? null : AppColors.primaryGradient,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GameButton(
                    label: 'Home',
                    onTap: () => context.go('/home'),
                    isOutlined: true,
                    color: AppColors.textSecondary,
                    width: double.infinity,
                  ),
                  // Watch ad for coins
                  if (result.isWin) ...[
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () {
                        // Show rewarded ad
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
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
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
        ),
        const SizedBox(width: AppSpacing.lg),
        _StatChip(
          icon: Icons.timer_rounded,
          value: _formatDuration(result.timeTaken),
          color: AppColors.logicColor,
        ),
        if (result.totalQuestions > 0) ...[
          const SizedBox(width: AppSpacing.lg),
          _StatChip(
            icon: Icons.check_circle_rounded,
            value: '${result.correctAnswers}/${result.totalQuestions}',
            color: AppColors.success,
          ),
        ],
      ],
    );
  }

  Widget _buildShareButton(GameResult result) {
    return GestureDetector(
      onTap: () {
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
    );
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


