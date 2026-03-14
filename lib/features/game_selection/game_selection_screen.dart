import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/game_type.dart';
import '../../core/widgets/premium_card.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl,
                ),
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
                    Text('Brain Games', style: AppTypography.headingLarge),
                  ],
                ),
              ),
              // Game list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: GameInfo.allGames.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final game = GameInfo.allGames[index];
                    return _GameListTile(game: game);
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

class _GameListTile extends StatelessWidget {
  final GameInfo game;

  const _GameListTile({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.isAvailable
          ? () => context.push('/games/${game.id}/levels')
          : null,
      child: AnimatedOpacity(
        opacity: game.isAvailable ? 1.0 : 0.5,
        duration: AppDurations.fast,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: game.isAvailable
                  ? game.color.withOpacity(0.15)
                  : AppColors.surfaceElevated,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Game icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: game.isAvailable
                      ? game.gradient
                      : const LinearGradient(
                          colors: [
                            AppColors.surfaceElevated,
                            AppColors.surfaceElevated,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: game.isAvailable
                      ? [
                          BoxShadow(
                            color: game.color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  game.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(game.name, style: AppTypography.headingSmall),
                        if (!game.isAvailable) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadius.roundAll,
                            ),
                            child: Text(
                              'SOON',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (game.isAvailable)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
