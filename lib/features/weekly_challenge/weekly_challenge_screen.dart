import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/premium_card.dart';

class WeeklyChallengeScreen extends ConsumerStatefulWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  ConsumerState<WeeklyChallengeScreen> createState() =>
      _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState extends ConsumerState<WeeklyChallengeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  WeeklyChallenge? _challenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final retention = ref.read(retentionServiceProvider);
    try {
      await retention.init();
      final challenge = await retention.loadWeeklyChallenge();
      if (mounted) {
        setState(() {
          _challenge = challenge;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Get the Monday-Sunday date range for the current week
  String _getWeekDateRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[monday.month - 1]} ${monday.day} - '
        '${months[sunday.month - 1]} ${sunday.day}';
  }

  IconData _getTaskIcon(WeeklyTaskType type) {
    switch (type) {
      case WeeklyTaskType.completeLevels:
        return Icons.check_circle_outline_rounded;
      case WeeklyTaskType.perfectScores:
        return Icons.star_rounded;
      case WeeklyTaskType.dailyChallenges:
        return Icons.calendar_today_rounded;
      case WeeklyTaskType.playSpecificGame:
        return Icons.games_rounded;
      case WeeklyTaskType.earnStars:
        return Icons.auto_awesome_rounded;
    }
  }

  Color _getTaskColor(WeeklyTaskType type) {
    switch (type) {
      case WeeklyTaskType.completeLevels:
        return AppColors.success;
      case WeeklyTaskType.perfectScores:
        return AppColors.gold;
      case WeeklyTaskType.dailyChallenges:
        return AppColors.primary;
      case WeeklyTaskType.playSpecificGame:
        return AppColors.puzzleColor;
      case WeeklyTaskType.earnStars:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weekly Challenge',
                              style: AppTypography.headingLarge),
                          Text(
                            _getWeekDateRange(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _challenge == null
                        ? Center(
                            child: Text(
                              'Could not load challenge',
                              style: AppTypography.bodyMedium,
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeController,
                            child: _buildContent(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final challenge = _challenge!;
    final completedCount = challenge.completedCount;
    final totalTasks = challenge.tasks.length;
    final overallProgress = challenge.progress;
    final allComplete = challenge.isComplete;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress Overview ──
          GradientBorderCard(
            gradient: allComplete
                ? AppColors.successGradient
                : AppColors.primaryGradient,
            child: Column(
              children: [
                Row(
                  children: [
                    // Progress circle
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: overallProgress,
                              backgroundColor:
                                  AppColors.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation(
                                allComplete
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              strokeWidth: 5,
                            ),
                          ),
                          Text(
                            '${(overallProgress * 100).toInt()}%',
                            style: AppTypography.labelLarge.copyWith(
                              color: allComplete
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allComplete
                                ? 'Challenge Complete!'
                                : '$completedCount / $totalTasks Tasks Complete',
                            style: AppTypography.headingSmall.copyWith(
                              color: allComplete
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allComplete
                                ? 'Amazing work this week!'
                                : 'Complete all tasks for bonus rewards',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Overall progress bar
                ClipRRect(
                  borderRadius: AppRadius.roundAll,
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(
                      allComplete ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Tasks Header ──
          Text('Tasks', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.md),

          // ── Task List ──
          ...List.generate(challenge.tasks.length, (index) {
            final task = challenge.tasks[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < challenge.tasks.length - 1
                    ? AppSpacing.md
                    : 0,
              ),
              child: _TaskCard(
                task: task,
                taskIndex: index + 1,
                icon: _getTaskIcon(task.type),
                color: _getTaskColor(task.type),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.xxl),

          // ── Overall Reward Section ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: allComplete
                  ? const LinearGradient(
                      colors: [Color(0xFF0D3320), Color(0xFF1A2A5E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF1A2A5E), Color(0xFF2B1A5E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: allComplete
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.15),
                width: allComplete ? 1.5 : 1,
              ),
              boxShadow: allComplete
                  ? AppShadows.glow(AppColors.success)
                  : null,
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: allComplete
                        ? AppColors.successGradient
                        : const LinearGradient(
                            colors: [
                              AppColors.surfaceElevated,
                              AppColors.surfaceElevated
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    allComplete
                        ? Icons.celebration_rounded
                        : Icons.lock_rounded,
                    color: allComplete
                        ? Colors.white
                        : AppColors.textDisabled,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Completion Bonus',
                  style: AppTypography.headingMedium.copyWith(
                    color: allComplete
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  allComplete
                      ? 'Rewards earned!'
                      : 'Complete all 5 tasks to unlock',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CompletionRewardChip(
                      icon: Icons.monetization_on_rounded,
                      value: '+${challenge.totalCoinReward}',
                      label: 'Coins',
                      color: AppColors.gold,
                      isActive: allComplete,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _CompletionRewardChip(
                      icon: Icons.auto_awesome_rounded,
                      value: '+${challenge.totalXpReward}',
                      label: 'XP',
                      color: AppColors.primary,
                      isActive: allComplete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

// ── Task Card ────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final WeeklyTask task;
  final int taskIndex;
  final IconData icon;
  final Color color;

  const _TaskCard({
    required this.task,
    required this.taskIndex,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = task.isComplete;
    final progress = task.progress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.successSurface.withOpacity(0.5)
            : AppColors.surfaceCard,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isComplete
              ? AppColors.success.withOpacity(0.3)
              : AppColors.surfaceElevated,
          width: isComplete ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Task icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withOpacity(0.15)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isComplete
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 24)
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              // Task description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Task $taskIndex',
                          style: AppTypography.labelSmall.copyWith(
                            color: isComplete
                                ? AppColors.success
                                : color,
                            fontSize: 10,
                          ),
                        ),
                        if (isComplete) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: AppRadius.roundAll,
                            ),
                            child: Text(
                              'DONE',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isComplete
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  '${task.current}/${task.target}',
                  style: AppTypography.labelMedium.copyWith(
                    color: isComplete ? AppColors.success : color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.roundAll,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? AppColors.success : color,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Reward Chip ───────────────────────────────────

class _CompletionRewardChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isActive;

  const _CompletionRewardChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppDurations.normal,
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(isActive ? 0.15 : 0.08),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: color.withOpacity(isActive ? 0.3 : 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.headingSmall.copyWith(
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
