import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/game_button.dart';

class DailyRewardsScreen extends ConsumerStatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  ConsumerState<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends ConsumerState<DailyRewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  DailyRewardState _rewardState = const DailyRewardState();
  bool _isLoading = true;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadState();
  }

  Future<void> _loadState() async {
    final retention = ref.read(retentionServiceProvider);
    try {
      await retention.init();
      final state = await retention.loadDailyRewardState();
      if (mounted) {
        setState(() {
          _rewardState = state;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _claimReward() async {
    if (_isClaiming || _rewardState.claimedToday) return;
    setState(() => _isClaiming = true);

    final retention = ref.read(retentionServiceProvider);
    final result = await retention.claimDailyReward();

    if (result.success && result.reward != null && mounted) {
      final reward = result.reward!;

      // Add coins to player data
      if (reward.coins > 0) {
        ref.read(playerDataProvider.notifier).addCoins(reward.coins);
      }
      if (reward.hints > 0) {
        ref.read(playerDataProvider.notifier).addHints(reward.hints);
      }

      setState(() {
        _rewardState = result.newState;
        _isClaiming = false;
      });

      if (mounted) {
        _showClaimDialog(reward);
      }
    } else {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  void _showClaimDialog(DailyReward reward) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppRadius.xlAll,
            border: Border.all(
              color: reward.isBonusDay
                  ? AppColors.gold.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: AppShadows.glow(
              reward.isBonusDay ? AppColors.gold : AppColors.primary,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: reward.isBonusDay
                      ? AppColors.goldGradient
                      : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                reward.isBonusDay ? 'Mega Bonus!' : 'Reward Claimed!',
                style: AppTypography.headingLarge.copyWith(
                  color: reward.isBonusDay
                      ? AppColors.gold
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (reward.coins > 0)
                _RewardRow(
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.gold,
                  text: '+${reward.coins} Coins',
                ),
              if (reward.xp > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _RewardRow(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  text: '+${reward.xp} XP',
                ),
              ],
              if (reward.hints > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _RewardRow(
                  icon: Icons.lightbulb_rounded,
                  color: AppColors.warning,
                  text: '+${reward.hints} Hint${reward.hints > 1 ? 's' : ''}',
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              GameButton(
                label: 'Awesome!',
                gradient: reward.isBonusDay
                    ? AppColors.goldGradient
                    : AppColors.primaryGradient,
                onTap: () => Navigator.of(ctx).pop(),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDay =
        _rewardState.consecutiveDays == 0 ? 1 : _rewardState.consecutiveDays;
    // The day index in the 7-day cycle (0-based)
    final cycleDay = ((currentDay - 1) % 7) + 1;
    final claimedToday = _rewardState.claimedToday;

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
                    Text('Daily Rewards', style: AppTypography.headingLarge),
                  ],
                ),
              ),

              // ── Streak info ──
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _rewardState.consecutiveDays > 0
                                  ? '${_rewardState.consecutiveDays} Day Streak'
                                  : 'Start Your Streak',
                              style: AppTypography.headingSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Log in daily to earn bigger rewards!',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── 7-Day Reward Calendar ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Column(
                          children: [
                            // Top row: Days 1-4
                            Row(
                              children: List.generate(4, (i) {
                                final reward =
                                    DailyRewardCalendar.rewards[i];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i < 3 ? AppSpacing.sm : 0,
                                    ),
                                    child: _DayCard(
                                      reward: reward,
                                      isClaimed: _isDayClaimed(
                                          reward.day, cycleDay, claimedToday),
                                      isCurrentDay: _isCurrentDay(
                                          reward.day, cycleDay, claimedToday),
                                      isFuture: _isFutureDay(
                                          reward.day, cycleDay, claimedToday),
                                      pulseAnimation: _pulseController,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Bottom row: Days 5-7
                            Row(
                              children: List.generate(3, (i) {
                                final reward =
                                    DailyRewardCalendar.rewards[i + 4];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i < 2 ? AppSpacing.sm : 0,
                                    ),
                                    child: _DayCard(
                                      reward: reward,
                                      isClaimed: _isDayClaimed(
                                          reward.day, cycleDay, claimedToday),
                                      isCurrentDay: _isCurrentDay(
                                          reward.day, cycleDay, claimedToday),
                                      isFuture: _isFutureDay(
                                          reward.day, cycleDay, claimedToday),
                                      pulseAnimation: _pulseController,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
              ),

              // ── Claim Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = claimedToday
                        ? 1.0
                        : 1.0 + (_pulseController.value * 0.03);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: GameButton(
                    label: claimedToday
                        ? 'Claimed Today'
                        : 'Claim Day $cycleDay Reward',
                    gradient: claimedToday
                        ? const LinearGradient(
                            colors: [
                              AppColors.surfaceElevated,
                              AppColors.surfaceElevated
                            ],
                          )
                        : (cycleDay == 7
                            ? AppColors.goldGradient
                            : AppColors.primaryGradient),
                    icon: claimedToday
                        ? Icons.check_circle_rounded
                        : Icons.card_giftcard_rounded,
                    onTap: claimedToday ? null : _claimReward,
                    isLoading: _isClaiming,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDayClaimed(int day, int cycleDay, bool claimedToday) {
    if (claimedToday) {
      return day <= cycleDay;
    }
    return day < cycleDay;
  }

  bool _isCurrentDay(int day, int cycleDay, bool claimedToday) {
    if (claimedToday) return false;
    return day == cycleDay;
  }

  bool _isFutureDay(int day, int cycleDay, bool claimedToday) {
    if (claimedToday) {
      return day > cycleDay;
    }
    return day > cycleDay;
  }
}

// ── Day Card Widget ──────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DailyReward reward;
  final bool isClaimed;
  final bool isCurrentDay;
  final bool isFuture;
  final AnimationController pulseAnimation;

  const _DayCard({
    required this.reward,
    required this.isClaimed,
    required this.isCurrentDay,
    required this.isFuture,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isBonusDay = reward.isBonusDay;
    final borderColor = isClaimed
        ? AppColors.success.withOpacity(0.4)
        : isCurrentDay
            ? (isBonusDay
                ? AppColors.gold.withOpacity(0.6)
                : AppColors.primary.withOpacity(0.6))
            : AppColors.surfaceElevated;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isCurrentDay
            ? 1.0 + (pulseAnimation.value * 0.04)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedOpacity(
        duration: AppDurations.normal,
        opacity: isFuture ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isClaimed
                ? AppColors.successSurface
                : isCurrentDay
                    ? (isBonusDay
                        ? AppColors.goldSurface
                        : AppColors.primarySurface)
                    : AppColors.surfaceCard,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isCurrentDay
                ? AppShadows.glow(
                    isBonusDay ? AppColors.gold : AppColors.primary)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isBonusDay
                      ? AppColors.gold.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  isBonusDay ? 'BONUS' : 'Day ${reward.day}',
                  style: AppTypography.labelSmall.copyWith(
                    color: isBonusDay
                        ? AppColors.gold
                        : isCurrentDay
                            ? AppColors.primary
                            : AppColors.textTertiary,
                    fontSize: isBonusDay ? 9 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Icon / Checkmark
              if (isClaimed)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                )
              else
                Icon(
                  isFuture
                      ? Icons.lock_rounded
                      : (isBonusDay
                          ? Icons.star_rounded
                          : Icons.card_giftcard_rounded),
                  color: isFuture
                      ? AppColors.textDisabled
                      : (isBonusDay ? AppColors.gold : AppColors.primary),
                  size: 28,
                ),
              const SizedBox(height: AppSpacing.sm),
              // Reward info
              if (reward.coins > 0)
                Text(
                  '${reward.coins}',
                  style: AppTypography.headingSmall.copyWith(
                    color: isClaimed
                        ? AppColors.success
                        : (isBonusDay ? AppColors.gold : AppColors.textPrimary),
                    fontSize: 15,
                  ),
                ),
              if (reward.coins > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: AppColors.gold.withOpacity(isFuture ? 0.5 : 1),
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'coins',
                      style: AppTypography.labelSmall.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              if (reward.hints > 0 && reward.coins == 0) ...[
                Text(
                  '${reward.hints}',
                  style: AppTypography.headingSmall.copyWith(
                    color: isClaimed
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 15,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color:
                          AppColors.warning.withOpacity(isFuture ? 0.5 : 1),
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      reward.hints == 1 ? 'hint' : 'hints',
                      style: AppTypography.labelSmall.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 2),
              // XP label
              Text(
                '+${reward.xp} XP',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary.withOpacity(isFuture ? 0.4 : 0.8),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reward Row (for dialog) ──────────────────────────────────

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RewardRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTypography.headingSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
