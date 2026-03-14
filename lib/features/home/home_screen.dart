import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/game_type.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/game_hud.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Load progress for all available games
    Future.microtask(() {
      for (final game in GameInfo.allGames.where((g) => g.isAvailable)) {
        ref.read(gameProgressProvider(game.id).notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: _buildHeader(player),
                ),
                // ── Streak Card ──
                SliverToBoxAdapter(
                  child: _buildStreakCard(player),
                ),
                // ── Daily Rewards ──
                SliverToBoxAdapter(
                  child: _buildDailyRewardsCard(),
                ),
                // ── Daily Challenge ──
                SliverToBoxAdapter(
                  child: _buildDailyChallengeCard(),
                ),
                // ── Quick Play Section ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Brain Games', style: AppTypography.headingLarge),
                        GestureDetector(
                          onTap: () => context.push(Routes.gameSelection),
                          child: Text(
                            'See All',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Game Cards Grid ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final game = GameInfo.allGames
                            .where((g) => g.isAvailable)
                            .toList()[index];
                        return _buildGameCard(game);
                      },
                      childCount: GameInfo.allGames
                          .where((g) => g.isAvailable)
                          .length,
                    ),
                  ),
                ),
                // ── Bottom Nav Shortcuts ──
                SliverToBoxAdapter(
                  child: _buildBottomActions(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(player) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.push(Routes.profile),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  'Ready to train?',
                  style: AppTypography.headingMedium,
                ),
              ],
            ),
          ),
          // Coins
          GestureDetector(
            onTap: () => context.push(Routes.shop),
            child: CoinDisplay(amount: player.coins),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(player) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
      ),
      child: GradientBorderCard(
        gradient: player.currentStreak > 0
            ? AppColors.accentGradient
            : const LinearGradient(colors: [
                AppColors.surfaceElevated,
                AppColors.surfaceElevated,
              ]),
        child: Row(
          children: [
            // Flame icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: player.currentStreak > 0
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: player.currentStreak > 0
                    ? AppColors.accent
                    : AppColors.textDisabled,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.currentStreak > 0
                        ? '${player.currentStreak} Day Streak!'
                        : 'Start Your Streak',
                    style: AppTypography.headingSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.currentStreak > 0
                        ? 'Keep going! Best: ${player.bestStreak} days'
                        : 'Play daily to build your streak',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            // Streak number
            if (player.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  '🔥 ${player.currentStreak}',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRewardsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
      ),
      child: GestureDetector(
        onTap: () => context.push(NewRoutes.dailyRewards),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B1A3E), Color(0xFF1A2A4E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: AppColors.gold.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Rewards',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Claim your daily coins & XP!',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  'CLAIM',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
      ),
      child: GestureDetector(
        onTap: () => context.push(Routes.dailyChallenge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2A5E), Color(0xFF2B1A5E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Calendar icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete 3 games for bonus rewards',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(GameInfo game) {
    final progress = ref.watch(gameProgressProvider(game.id));
    final maxStars = GameConstants.levelsPerMode * 3;
    final progressValue = maxStars > 0
        ? progress.totalStarsEarned / maxStars
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/games/${game.id}/levels'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: game.color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: game.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: game.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  game.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                game.name,
                style: AppTypography.headingSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                game.shortDescription,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Progress indicator
              ClipRRect(
                borderRadius: AppRadius.roundAll,
                child: LinearProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(game.color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
      ),
      child: Column(
        children: [
          // Top row - engagement features
          Row(
            children: [
              Expanded(
                child: _BottomActionTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  color: AppColors.gold,
                  onTap: () => context.push(NewRoutes.achievements),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _BottomActionTile(
                  icon: Icons.assignment_rounded,
                  label: 'Weekly',
                  color: AppColors.success,
                  onTap: () => context.push(NewRoutes.weeklyChallenge),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Bottom row - utility features
          Row(
            children: [
              Expanded(
                child: _BottomActionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  color: AppColors.logicColor,
                  onTap: () => context.push(Routes.profile),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _BottomActionTile(
                  icon: Icons.store_rounded,
                  label: 'Shop',
                  color: AppColors.gold,
                  onTap: () => context.push(Routes.shop),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _BottomActionTile(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: AppColors.textSecondary,
                  onTap: () => context.push(Routes.settings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _BottomActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: AppColors.surfaceElevated,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
