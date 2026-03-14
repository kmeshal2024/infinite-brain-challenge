import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_hud.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerDataProvider);

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
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Shop', style: AppTypography.headingLarge),
                    const Spacer(),
                    CoinDisplay(amount: player.coins),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free coins section
                      Text('Free Rewards', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      _ShopItem(
                        icon: Icons.play_circle_filled_rounded,
                        title: 'Watch Ad',
                        subtitle: 'Watch a short video for coins',
                        reward: '+${GameConstants.coinsRewardedAd} coins',
                        color: AppColors.success,
                        onTap: () async {
                          final adService = ref.read(adServiceProvider);
                          final granted = await adService.showRewardedAd();
                          if (granted) {
                            ref.read(playerDataProvider.notifier).addCoins(
                                  GameConstants.coinsRewardedAd,
                                );
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // Hints section
                      Text('Hints', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      _ShopItem(
                        icon: Icons.lightbulb_rounded,
                        title: '3 Hints',
                        subtitle: 'Get help in tricky levels',
                        reward: '60 coins',
                        color: AppColors.warning,
                        onTap: player.coins >= 60
                            ? () {
                                ref.read(playerDataProvider.notifier).spendCoins(60);
                                ref.read(playerDataProvider.notifier).addHints(3);
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ShopItem(
                        icon: Icons.lightbulb_rounded,
                        title: '10 Hints',
                        subtitle: 'Best value!',
                        reward: '150 coins',
                        color: AppColors.warning,
                        isBestValue: true,
                        onTap: player.coins >= 150
                            ? () {
                                ref.read(playerDataProvider.notifier).spendCoins(150);
                                ref.read(playerDataProvider.notifier).addHints(10);
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // Premium section
                      Text('Premium', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B1A5E), Color(0xFF1A2A5E)],
                          ),
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.block_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text('Remove Ads',
                                style: AppTypography.headingMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Enjoy ad-free gameplay forever',
                              style: AppTypography.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            GameButton(
                              label: player.hasRemovedAds
                                  ? 'Purchased ✓'
                                  : 'Coming Soon',
                              gradient: AppColors.goldGradient,
                              onTap: player.hasRemovedAds ? null : () {},
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.huge),
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
}

class _ShopItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String reward;
  final Color color;
  final VoidCallback? onTap;
  final bool isBestValue;

  const _ShopItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.color,
    this.onTap,
    this.isBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.5,
        duration: AppDurations.fast,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: isBestValue
                  ? color.withOpacity(0.3)
                  : AppColors.surfaceElevated,
              width: isBestValue ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: AppTypography.headingSmall),
                        if (isBestValue) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: AppRadius.roundAll,
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  reward,
                  style: AppTypography.labelMedium.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
