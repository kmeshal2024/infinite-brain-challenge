import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// A premium-styled button with gradient, glow, and tap feedback.
class GameButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final Color? color;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;
  final bool isLoading;
  final double? width;

  const GameButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradient,
    this.color,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
    this.isLoading = false,
    this.width,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;
    final height = widget.isSmall ? 44.0 : 52.0;
    final isDisabled = widget.onTap == null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _controller.reverse();
                widget.onTap?.call();
              },
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: widget.width,
            height: height,
            decoration: BoxDecoration(
              gradient: widget.isOutlined ? null : gradient,
              borderRadius: AppRadius.mdAll,
              border: widget.isOutlined
                  ? Border.all(
                      color: widget.color ?? AppColors.primary,
                      width: 1.5,
                    )
                  : null,
              boxShadow: widget.isOutlined
                  ? null
                  : [
                      BoxShadow(
                        color: (widget.color ?? AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.isOutlined
                                ? (widget.color ?? AppColors.primary)
                                : Colors.white,
                            size: widget.isSmall ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: AppTypography.buttonText.copyWith(
                            fontSize: widget.isSmall ? 14 : 16,
                            color: widget.isOutlined
                                ? (widget.color ?? AppColors.primary)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}


