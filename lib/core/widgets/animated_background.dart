import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_tokens.dart';

/// Subtle animated background with floating particles and gradient.
/// Optimized with RepaintBoundary to prevent unnecessary repaints of child widgets.
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
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pre-generate particles for consistent performance
    final rng = math.Random(42);
    _particles = List.generate(12, (i) => _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 2 + rng.nextDouble() * 4,
      speedX: (rng.nextDouble() - 0.5) * 0.3,
      speedY: (rng.nextDouble() - 0.5) * 0.2,
      opacity: 0.04 + rng.nextDouble() * 0.08,
      phase: rng.nextDouble() * math.pi * 2,
    ));
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
      child: Stack(
        children: [
          // Background animation layer - isolated from child repaints
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BackgroundPainter(
                      progress: _controller.value,
                      accentColor: widget.accentColor ?? AppColors.primary,
                      particles: _particles,
                    ),
                    isComplex: true,
                    willChange: true,
                  );
                },
              ),
            ),
          ),
          // Child content - won't repaint when background animates
          RepaintBoundary(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, y, radius, speedX, speedY, opacity, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.phase,
  });
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final List<_Particle> particles;

  _BackgroundPainter({
    required this.progress,
    required this.accentColor,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final t = progress * 2 * math.pi;

    // Large ambient orbs (3)
    paint.color = accentColor.withOpacity(0.025);
    canvas.drawCircle(
      Offset(
        size.width * 0.3 + math.sin(t) * 30,
        size.height * 0.2 + math.cos(t) * 20,
      ),
      120,
      paint,
    );

    paint.color = accentColor.withOpacity(0.018);
    canvas.drawCircle(
      Offset(
        size.width * 0.7 + math.cos(t + 1) * 25,
        size.height * 0.6 + math.sin(t + 1) * 30,
      ),
      100,
      paint,
    );

    paint.color = AppColors.accent.withOpacity(0.012);
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + math.sin(t + 2) * 20,
        size.height * 0.8 + math.cos(t + 2) * 15,
      ),
      80,
      paint,
    );

    // Floating particles
    for (final p in particles) {
      final px = (p.x + math.sin(t * p.speedX + p.phase) * 0.05) * size.width;
      final py = (p.y + math.cos(t * p.speedY + p.phase) * 0.04) * size.height;

      paint.color = accentColor.withOpacity(p.opacity);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
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
