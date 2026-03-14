import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_tokens.dart';

/// Subtle animated background with floating particles and gradient.
class AnimatedGameBackground extends StatefulWidget {
  final Widget child;
  final Color? accentColor;

  const AnimatedGameBackground({
    super.key,
    required this.child,
    this.accentColor,
  });

  @override
  State<AnimatedGameBackground> createState() =>
      _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              progress: _controller.value,
              accentColor: widget.accentColor ?? AppColors.primary,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _BackgroundPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle floating circles
    final paint = Paint()..style = PaintingStyle.fill;

    // Orb 1 - large subtle glow
    paint.color = accentColor.withOpacity(0.03);
    final orb1X = size.width * 0.3 + math.sin(progress * 2 * math.pi) * 30;
    final orb1Y = size.height * 0.2 + math.cos(progress * 2 * math.pi) * 20;
    canvas.drawCircle(Offset(orb1X, orb1Y), 120, paint);

    // Orb 2
    paint.color = accentColor.withOpacity(0.02);
    final orb2X =
        size.width * 0.7 + math.cos(progress * 2 * math.pi + 1) * 25;
    final orb2Y =
        size.height * 0.6 + math.sin(progress * 2 * math.pi + 1) * 30;
    canvas.drawCircle(Offset(orb2X, orb2Y), 100, paint);

    // Orb 3
    paint.color = AppColors.accent.withOpacity(0.015);
    final orb3X =
        size.width * 0.5 + math.sin(progress * 2 * math.pi + 2) * 20;
    final orb3Y =
        size.height * 0.8 + math.cos(progress * 2 * math.pi + 2) * 15;
    canvas.drawCircle(Offset(orb3X, orb3Y), 80, paint);

    // Small dots
    paint.color = accentColor.withOpacity(0.08);
    for (int i = 0; i < 5; i++) {
      final dotX = (size.width * (0.1 + i * 0.2)) +
          math.sin(progress * 2 * math.pi + i) * 10;
      final dotY = (size.height * (0.15 + i * 0.15)) +
          math.cos(progress * 2 * math.pi + i) * 8;
      canvas.drawCircle(Offset(dotX, dotY), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) {
    return old.progress != progress;
  }
}

/// Simpler static gradient scaffold background
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}


