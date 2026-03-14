import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/models.dart';
import '../../core/services/services.dart';
import '../../core/widgets/premium_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementService = ref.read(achievementServiceProvider);
    final allAchievements = Achievements.all;
    final unlockedCount = achievementService.unlockedCount;
    final totalCount = allAchievements.length;
    final progressPercent = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
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
                    Text('Achievements', style: AppTypography.headingLarge),
                  ],
                ),
              ),

              // ── Stats Summary ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  width: double.infinity,
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
                    ),
                  ),
                  child: Row(
                    children: [
                      // Trophy icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
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
                              '$unlockedCount / $totalCount Unlocked',
                              style: AppTypography.headingSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: AppRadius.roundAll,
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                backgroundColor: AppColors.surfaceElevated,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.gold),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: AppRadius.roundAll,
                        ),
                        child: Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Category Filter Chips ──
              SizedBox(
                height: 40,
                child: _CategoryFilterBar(),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Achievement List ──
              Expanded(
                child: _AchievementList(
                  achievementService: achievementService,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Filter State ────────────────────────────────────

final _selectedCategoryProvider =
    StateProvider<AchievementCategory?>((ref) => null);

class _CategoryFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedCategoryProvider);

    final categories = [
      (null, 'All', Icons.grid_view_rounded),
      (AchievementCategory.gameplay, 'Gameplay', Icons.games_rounded),
      (AchievementCategory.mastery, 'Mastery', Icons.psychology_rounded),
      (
        AchievementCategory.collection,
        'Collection',
        Icons.collections_rounded
      ),
      (
        AchievementCategory.streak,
        'Streak',
        Icons.local_fire_department_rounded
      ),
      (AchievementCategory.special, 'Special', Icons.auto_awesome_rounded),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final (category, label, icon) = categories[index];
        final isSelected = selected == category;

        return GestureDetector(
          onTap: () {
            ref.read(_selectedCategoryProvider.notifier).state = category;
          },
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surfaceCard,
              borderRadius: AppRadius.roundAll,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.surfaceElevated,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Achievement List ─────────────────────────────────────────

class _AchievementList extends ConsumerWidget {
  final AchievementService achievementService;

  const _AchievementList({required this.achievementService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final allAchievements = Achievements.all;

    final filtered = selectedCategory == null
        ? allAchievements
        : allAchievements
            .where((a) => a.category == selectedCategory)
            .toList();

    // Sort: unlocked first, then by category
    final sorted = List<Achievement>.from(filtered);
    sorted.sort((a, b) {
      final aProgress = achievementService.getProgress(a.id);
      final bProgress = achievementService.getProgress(b.id);
      if (aProgress.isUnlocked && !bProgress.isUnlocked) return -1;
      if (!aProgress.isUnlocked && bProgress.isUnlocked) return 1;
      // Then by progress percentage
      final aPercent =
          a.target > 0 ? aProgress.currentValue / a.target : 0.0;
      final bPercent =
          b.target > 0 ? bProgress.currentValue / b.target : 0.0;
      return bPercent.compareTo(aPercent);
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.huge,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final achievement = sorted[index];
        final progress = achievementService.getProgress(achievement.id);
        return _AchievementCard(
          achievement: achievement,
          progress: progress,
        );
      },
    );
  }
}

// ── Achievement Card ─────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress progress;

  const _AchievementCard({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress.isUnlocked;
    final progressValue = achievement.target > 0
        ? (progress.currentValue / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.successSurface.withOpacity(0.5)
            : AppColors.surfaceCard,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isUnlocked
              ? AppColors.success.withOpacity(0.3)
              : AppColors.surfaceElevated,
          width: isUnlocked ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Achievement icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withOpacity(0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: isUnlocked
                  ? Border.all(
                      color: achievement.color.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  achievement.icon,
                  color: isUnlocked
                      ? achievement.color
                      : AppColors.textDisabled,
                  size: 26,
                ),
                if (isUnlocked)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: AppTypography.headingSmall.copyWith(
                          color: isUnlocked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: AppRadius.roundAll,
                        ),
                        child: Text(
                          'Unlocked',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isUnlocked
                        ? AppColors.textTertiary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Progress bar or unlock date
                if (isUnlocked && progress.unlockedAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        DateFormat('MMM d, yyyy').format(progress.unlockedAt!),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.roundAll,
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation(
                              achievement.color.withOpacity(0.8),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${progress.currentValue}/${achievement.target}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Reward info
          Column(
            children: [
              if (achievement.xpReward > 0) ...[
                _MiniRewardBadge(
                  icon: Icons.auto_awesome_rounded,
                  value: '+${achievement.xpReward}',
                  color: AppColors.primary,
                  isEarned: isUnlocked,
                ),
              ],
              if (achievement.coinReward > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _MiniRewardBadge(
                  icon: Icons.monetization_on_rounded,
                  value: '+${achievement.coinReward}',
                  color: AppColors.gold,
                  isEarned: isUnlocked,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini Reward Badge ────────────────────────────────────────

class _MiniRewardBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final bool isEarned;

  const _MiniRewardBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isEarned ? 0.15 : 0.08),
        borderRadius: AppRadius.roundAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.withOpacity(isEarned ? 1 : 0.5),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: color.withOpacity(isEarned ? 1 : 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
