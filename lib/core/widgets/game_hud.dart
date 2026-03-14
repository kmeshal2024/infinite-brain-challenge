import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Compact coin display for headers and HUD
class CoinDisplay extends StatelessWidget {
  final int amount;
  final bool isCompact;

  const CoinDisplay({
    super.key,
    required this.amount,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
        vertical: isCompact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldSurface,
        borderRadius: AppRadius.roundAll,
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            color: AppColors.gold,
            size: isCompact ? 16 : 20,
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(amount),
            style: AppTypography.coinText.copyWith(
              fontSize: isCompact ? 13 : 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

/// Star rating display (0-3 stars)
class StarDisplay extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;

  const StarDisplay({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final isFilled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFilled ? AppColors.gold : AppColors.textDisabled,
            size: size,
          ),
        );
      }),
    );
  }
}

/// In-game HUD bar showing level, score, and controls
class GameHUD extends StatelessWidget {
  final String title;
  final int? level;
  final int? score;
  final int? hints;
  final VoidCallback? onPause;
  final VoidCallback? onHint;

  const GameHUD({
    super.key,
    required this.title,
    this.level,
    this.score,
    this.hints,
    this.onPause,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Back / Pause
            _HudButton(
              icon: Icons.pause_rounded,
              onTap: onPause,
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + Level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (level != null)
                    Text(
                      'Level $level',
                      style: AppTypography.headingSmall,
                    ),
                ],
              ),
            ),
            // Score
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.roundAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$score',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            // Hint button
            if (hints != null && onHint != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _HudButton(
                icon: Icons.lightbulb_outline_rounded,
                badge: hints.toString(),
                onTap: onHint,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;
  final Color? color;

  const _HudButton({
    required this.icon,
    this.badge,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: AppColors.surfaceElevated,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: color ?? AppColors.textSecondary,
              size: 22,
            ),
            if (badge != null)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

/// Animated score counter
class AnimatedScore extends StatelessWidget {
  final int score;
  final TextStyle? style;

  const AnimatedScore({
    super.key,
    required this.score,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: score),
      duration: AppDurations.slow,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: style ?? AppTypography.gameScore,
        );
      },
    );
  }
}
