import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/game_type.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/game_hud.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  final String gameId;

  const LevelSelectionScreen({super.key, required this.gameId});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Load progress for this game
    Future.microtask(() {
      ref.read(gameProgressProvider(widget.gameId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = GameInfo.getById(widget.gameId);
    final progress = ref.watch(gameProgressProvider(widget.gameId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.name, style: AppTypography.headingLarge),
                          Text(
                            '${progress.totalStarsEarned} ⭐ earned',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Star counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: game.color.withOpacity(0.1),
                        borderRadius: AppRadius.roundAll,
                        border: Border.all(
                          color: game.color.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: game.color, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${progress.totalStarsEarned}/${GameConstants.levelsPerMode * 3}',
                            style: AppTypography.labelLarge.copyWith(
                              color: game.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Level grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: GameConstants.levelsPerMode,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final isUnlocked = progress.isLevelUnlocked(level);
                    final isCompleted = progress.isLevelCompleted(level);
                    final stars = progress.starsForLevel(level);
                    final isCurrent = level == progress.highestLevelUnlocked;

                    return _LevelButton(
                      level: level,
                      isUnlocked: isUnlocked,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      stars: stars,
                      color: game.color,
                      gradient: game.gradient,
                      onTap: isUnlocked
                          ? () => context.push(
                                '/games/${widget.gameId}/play/$level',
                              )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final int stars;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _LevelButton({
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.stars,
    required this.color,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isCurrent ? gradient : null,
              color: isCompleted
                  ? color.withOpacity(0.15)
                  : isUnlocked
                      ? AppColors.surfaceCard
                      : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? Colors.transparent
                    : isCompleted
                        ? color.withOpacity(0.3)
                        : isUnlocked
                            ? AppColors.surfaceElevated
                            : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(
                      '$level',
                      style: AppTypography.labelLarge.copyWith(
                        color: isCurrent
                            ? Colors.white
                            : isCompleted
                                ? color
                                : AppColors.textSecondary,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      ),
                    )
                  : Icon(
                      Icons.lock_rounded,
                      color: AppColors.textDisabled,
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          // Stars
          if (isCompleted)
            StarDisplay(stars: stars, size: 10)
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
