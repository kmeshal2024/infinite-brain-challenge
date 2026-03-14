import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A premium surface card with optional gradient border and glow.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? glowColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.surfaceCard)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : Border.all(color: AppColors.surfaceElevated, width: 0.5),
        boxShadow: hasGlow
            ? AppShadows.glowColor(glowColor ?? AppColors.primary)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Gradient-bordered card for highlighted sections
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient gradient;
  final double borderWidth;
  final double borderRadius;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient = AppColors.primaryGradient,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}
