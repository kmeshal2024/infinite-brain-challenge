import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════
// 1. ACHIEVEMENT POPUP
// ═══════════════════════════════════════════════════════════════════

/// Animated dialog overlay shown when an achievement is unlocked.
///
/// Displays the achievement icon, name, description, XP + coin rewards,
/// and an "Awesome!" dismiss button inside a dark card with colored glow.
class AchievementPopup extends StatefulWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final int coinReward;
  final VoidCallback onDismiss;

  const AchievementPopup({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpReward,
    required this.coinReward,
    required this.onDismiss,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.gameReveal,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: widget.color.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Achievement icon ---
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.color,
                      widget.color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: AppShadows.glow(widget.color),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: AppIconSize.xl,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- "Achievement Unlocked" label ---
              Text(
                'ACHIEVEMENT UNLOCKED',
                style: AppTypography.labelSmall.copyWith(
                  color: widget.color,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // --- Name ---
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.sm),

              // --- Description ---
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Rewards row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RewardChip(
                    icon: Icons.auto_awesome_rounded,
                    label: '+${widget.xpReward} XP',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _RewardChip(
                    icon: Icons.monetization_on_rounded,
                    label: '+${widget.coinReward}',
                    color: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Dismiss button ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color, widget.color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'Awesome!',
                      style: AppTypography.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
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

/// Small pill showing a reward value (used inside [AchievementPopup]).
class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.label,
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
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.roundAll,
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 2. LEVEL UP ANIMATION
// ═══════════════════════════════════════════════════════════════════

/// Full-screen overlay celebrating a player level-up.
///
/// Shows a gold-gradient "LEVEL UP!" heading, the new level number,
/// title, shimmer particles, and a "Continue" button.
/// Auto-dismisses after 3 seconds or on tap.
class LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final String title;
  final VoidCallback onDismiss;

  const LevelUpAnimation({
    super.key,
    required this.newLevel,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideIn;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: AppDurations.celebration,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _scaleIn = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );
    _slideIn = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Shimmer loop
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _entryController.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), _handleDismiss);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _entryController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleDismiss,
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeIn.value,
            child: Container(
              color: Colors.black.withOpacity(0.75 * _fadeIn.value),
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Shimmer particles
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ShimmerParticlePainter(
                    progress: _shimmerController.value,
                    color: AppColors.gold,
                  ),
                );
              },
            ),

            // Content
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideIn.value),
                  child: Transform.scale(
                    scale: _scaleIn.value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "LEVEL UP!" with gold gradient
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.goldGradient.createShader(bounds),
                      child: Text(
                        'LEVEL UP!',
                        style: GoogleFonts.nunito(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          height: 1.0,
                          color: Colors.white, // masked by shader
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Level circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: AppShadows.glow(AppColors.gold),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.newLevel}',
                          style: GoogleFonts.nunito(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.background,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),

                    // Continue button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                          width: 1.5,
                        ),
                        borderRadius: AppRadius.roundAll,
                      ),
                      child: Text(
                        'Continue',
                        style: AppTypography.buttonText.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints floating shimmer particles for the [LevelUpAnimation].
class _ShimmerParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  static final List<_Particle> _particles = List.generate(
    30,
    (i) => _Particle(
      x: (i * 37 % 100) / 100,
      y: (i * 53 % 100) / 100,
      size: 2.0 + (i % 4) * 1.5,
      speed: 0.5 + (i % 5) * 0.3,
      phase: (i * 73 % 100) / 100,
    ),
  );

  _ShimmerParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final px = p.x * size.width +
          math.sin(t * 2 * math.pi + p.phase * math.pi) * 20;
      final py = size.height * (1.0 - t);
      final alpha = math.sin(t * math.pi); // fade in/out over lifetime
      paint.color = color.withOpacity(0.6 * alpha);
      canvas.drawCircle(Offset(px, py), p.size * alpha, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShimmerParticlePainter old) =>
      old.progress != progress;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

// ═══════════════════════════════════════════════════════════════════
// 3. XP PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════

/// Compact horizontal XP progress bar with a level badge.
///
/// Shows the current level on the left, an animated gradient fill bar,
/// and "current / needed XP" on the right.
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final int level;
  final String title;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.level,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = xpForNextLevel > 0
        ? (currentXp / xpForNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        // Level badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Bar + labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + XP label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    '$currentXp / $xpForNextLevel XP',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Animated bar
              SizedBox(
                height: 10,
                child: ClipRRect(
                  borderRadius: AppRadius.roundAll,
                  child: Stack(
                    children: [
                      // Track
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.roundAll,
                        ),
                      ),
                      // Fill
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: fraction),
                        duration: AppDurations.slow,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: AppRadius.roundAll,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 4. DAILY REWARD CARD
// ═══════════════════════════════════════════════════════════════════

/// Compact card representing a single day in a daily-reward streak.
///
/// Visual states:
/// - **Claimed**: green check, slightly muted.
/// - **Today**: pulsing glow, highlighted border.
/// - **Future**: dimmed appearance.
/// - **Bonus day**: gold accent instead of primary.
class DailyRewardCard extends StatefulWidget {
  final int day;
  final int coins;
  final int xp;
  final int hints;
  final bool isClaimed;
  final bool isToday;
  final bool isBonusDay;

  const DailyRewardCard({
    super.key,
    required this.day,
    required this.coins,
    required this.xp,
    required this.hints,
    this.isClaimed = false,
    this.isToday = false,
    this.isBonusDay = false,
  });

  @override
  State<DailyRewardCard> createState() => _DailyRewardCardState();
}

class _DailyRewardCardState extends State<DailyRewardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isToday && !widget.isClaimed) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.isBonusDay ? AppColors.gold : AppColors.primary;

  IconData get _rewardIcon {
    if (widget.hints > 0) return Icons.lightbulb_outline_rounded;
    if (widget.coins > 0) return Icons.monetization_on_rounded;
    return Icons.auto_awesome_rounded;
  }

  String get _rewardLabel {
    if (widget.coins > 0) return '+${widget.coins}';
    if (widget.xp > 0) return '+${widget.xp} XP';
    if (widget.hints > 0) return '+${widget.hints}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isFuture = !widget.isClaimed && !widget.isToday;
    final effectiveOpacity = isFuture ? 0.45 : 1.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glowOpacity =
            widget.isToday && !widget.isClaimed ? _pulseAnimation.value : 0.0;

        return Opacity(
          opacity: effectiveOpacity,
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: widget.isClaimed
                    ? AppColors.success.withOpacity(0.4)
                    : widget.isToday
                        ? _accentColor.withOpacity(0.6)
                        : AppColors.surfaceElevated,
                width: widget.isToday ? 1.5 : 1,
              ),
              boxShadow: widget.isToday && !widget.isClaimed
                  ? [
                      BoxShadow(
                        color:
                            _accentColor.withOpacity(0.25 * glowOpacity),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day label
          Text(
            'Day ${widget.day}',
            style: AppTypography.labelSmall.copyWith(
              color: widget.isBonusDay
                  ? AppColors.gold
                  : AppColors.textTertiary,
              fontWeight:
                  widget.isBonusDay ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isClaimed
                  ? AppColors.successSurface
                  : _accentColor.withOpacity(0.12),
              border: Border.all(
                color: widget.isClaimed
                    ? AppColors.success.withOpacity(0.3)
                    : _accentColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Icon(
              widget.isClaimed ? Icons.check_rounded : _rewardIcon,
              color: widget.isClaimed ? AppColors.success : _accentColor,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Reward amount
          Text(
            widget.isClaimed ? 'Claimed' : _rewardLabel,
            style: AppTypography.labelMedium.copyWith(
              color: widget.isClaimed
                  ? AppColors.success
                  : widget.isBonusDay
                      ? AppColors.gold
                      : AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 5. SHARE SCORE CARD
// ═══════════════════════════════════════════════════════════════════

/// Shareable card widget designed for screenshots and sharing.
///
/// Displays app branding, game name, score, star rating, level, and
/// an optional "Perfect!" badge on a dark gradient background.
class ShareScoreCard extends StatelessWidget {
  final String gameName;
  final int score;
  final int stars;
  final int level;
  final bool isPerfect;

  const ShareScoreCard({
    super.key,
    required this.gameName,
    required this.score,
    required this.stars,
    required this.level,
    this.isPerfect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF161929),
            Color(0xFF1A1F3A),
            Color(0xFF0D0F1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.surfaceElevated,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Infinite Brain',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.surfaceElevated,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Game name
          Text(
            gameName,
            textAlign: TextAlign.center,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Score
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              '$score',
              style: GoogleFonts.nunito(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1.0,
                color: Colors.white, // masked by shader
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'SCORE',
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 2,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? AppColors.gold : AppColors.textDisabled,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Level + Perfect badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShareInfoChip(
                icon: Icons.trending_up_rounded,
                label: 'Level $level',
                color: AppColors.primary,
              ),
              if (isPerfect) ...[
                const SizedBox(width: AppSpacing.sm),
                _ShareInfoChip(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Perfect!',
                  color: AppColors.gold,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Footer
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.surfaceElevated,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Challenge your brain daily!',
            style: AppTypography.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip used inside [ShareScoreCard].
class _ShareInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ShareInfoChip({
    required this.icon,
    required this.label,
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
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
