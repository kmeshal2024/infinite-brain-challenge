// Generates a 1024x1024 brain-themed app icon using the `image` package
// Run: dart run tool/generate_icon.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Fill with dark background
  final bgColor = img.ColorRgba8(13, 15, 26, 255); // #0D0F1A
  img.fill(image, color: bgColor);

  // Draw rounded rectangle background with subtle gradient
  _drawGradientBackground(image, size);

  // Draw brain silhouette
  _drawBrain(image, size);

  // Draw infinity symbol
  _drawInfinity(image, size);

  // Draw neural dots
  _drawNeuralDots(image, size);

  // Draw subtle border glow
  _drawBorderGlow(image, size);

  // Save
  final outputDir = Directory('assets/icon');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }
  final pngBytes = img.encodePng(image);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('Icon generated: assets/icon/app_icon.png (${pngBytes.length} bytes)');
}

void _drawGradientBackground(img.Image image, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final maxDist = size * 0.7;

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      final t = (dist / maxDist).clamp(0.0, 1.0);

      // Radial gradient from #1A1F3A center to #0D0F1A edges
      final r = _lerp(26, 13, t).round();
      final g = _lerp(31, 15, t).round();
      final b = _lerp(58, 26, t).round();

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

void _drawBrain(img.Image image, int size) {
  final cx = size ~/ 2;
  final cy = (size * 0.42).round();
  final brainRadius = (size * 0.28).round();

  // Draw brain using two overlapping ellipses (hemispheres)
  // Left hemisphere
  _drawFilledEllipse(image, cx - brainRadius ~/ 4, cy,
      (brainRadius * 0.85).round(), brainRadius,
      img.ColorRgba8(108, 99, 255, 220)); // #6C63FF

  // Right hemisphere
  _drawFilledEllipse(image, cx + brainRadius ~/ 4, cy,
      (brainRadius * 0.85).round(), brainRadius,
      img.ColorRgba8(0, 217, 255, 220)); // #00D9FF

  // Overlap blend area (center)
  _drawFilledEllipse(image, cx, cy,
      (brainRadius * 0.3).round(), (brainRadius * 0.9).round(),
      img.ColorRgba8(91, 141, 239, 180)); // blend

  // Brain folds - horizontal curves
  final foldColor = img.ColorRgba8(255, 255, 255, 50);
  for (var i = -2; i <= 2; i++) {
    final foldY = cy + (i * brainRadius ~/ 3);
    _drawWavyLine(image, cx - brainRadius, cx + brainRadius, foldY,
        (brainRadius * 0.08).round(), foldColor, 2);
  }

  // Center divide line
  final divideColor = img.ColorRgba8(255, 255, 255, 80);
  _drawThickLine(image, cx, cy - brainRadius + 20, cx, cy + brainRadius - 20, divideColor, 3);

  // Brain stem
  _drawFilledEllipse(image, cx, cy + brainRadius - 10,
      (brainRadius * 0.15).round(), (brainRadius * 0.25).round(),
      img.ColorRgba8(80, 70, 200, 200));

  // Top bumps
  _drawFilledCircle(image, cx - brainRadius ~/ 2, cy - brainRadius + 30,
      (brainRadius * 0.35).round(),
      img.ColorRgba8(120, 110, 255, 100));
  _drawFilledCircle(image, cx + brainRadius ~/ 2, cy - brainRadius + 30,
      (brainRadius * 0.35).round(),
      img.ColorRgba8(30, 200, 255, 100));
}

void _drawInfinity(img.Image image, int size) {
  final cx = size ~/ 2;
  final cy = (size * 0.78).round();
  final w = (size * 0.12).round();
  final h = (size * 0.05).round();

  // Draw infinity symbol using parametric curve
  for (var t = 0.0; t < 2 * pi; t += 0.002) {
    final scale = 1.0 / (1.0 + sin(t) * sin(t) * 0.3);
    final x = cx + (w * cos(t) / (1 + sin(t) * sin(t))).round();
    final y = cy + (h * sin(t) * cos(t) / (1 + sin(t) * sin(t))).round();

    // Gradient along the curve
    final colorT = (t / (2 * pi));
    final r = _lerp(0, 108, colorT).round().clamp(0, 255);
    final g = _lerp(217, 99, colorT).round().clamp(0, 255);
    final b = _lerp(255, 255, colorT).round().clamp(0, 255);

    // Draw thick point with glow
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        final dist = sqrt(dx * dx + dy * dy);
        if (dist <= 4) {
          final alpha = ((1.0 - dist / 4.0) * 255).round().clamp(0, 255);
          final px = x + dx;
          final py = y + dy;
          if (px >= 0 && px < size && py >= 0 && py < size) {
            _blendPixel(image, px, py, r, g, b, alpha);
          }
        }
      }
    }
  }
}

void _drawNeuralDots(img.Image image, int size) {
  final cx = size ~/ 2;
  final cy = (size * 0.42).round();
  final rng = Random(42);

  final dots = <List<int>>[];
  // Generate dots within brain area
  for (var i = 0; i < 15; i++) {
    final angle = rng.nextDouble() * 2 * pi;
    final radius = rng.nextDouble() * size * 0.22;
    final x = cx + (cos(angle) * radius).round();
    final y = cy + (sin(angle) * radius * 0.85).round();
    dots.add([x, y]);
  }

  // Draw connections
  for (var i = 0; i < dots.length; i++) {
    for (var j = i + 1; j < dots.length; j++) {
      final dist = sqrt(pow(dots[i][0] - dots[j][0], 2) + pow(dots[i][1] - dots[j][1], 2));
      if (dist < size * 0.2) {
        _drawThickLine(image, dots[i][0], dots[i][1], dots[j][0], dots[j][1],
            img.ColorRgba8(255, 255, 255, 25), 1);
      }
    }
  }

  // Draw glowing dots
  for (final dot in dots) {
    _drawGlowingDot(image, dot[0], dot[1], 8,
        img.ColorRgba8(255, 255, 255, 200));
  }
}

void _drawBorderGlow(img.Image image, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final radius = size * 0.46;
  final thickness = size * 0.02;

  for (var angle = 0.0; angle < 2 * pi; angle += 0.001) {
    final x = cx + cos(angle) * radius;
    final y = cy + sin(angle) * radius;

    // Color cycling around the border
    final t = angle / (2 * pi);
    int r, g, b;
    if (t < 0.33) {
      r = _lerp(108, 0, t * 3).round();
      g = _lerp(99, 217, t * 3).round();
      b = 255;
    } else if (t < 0.66) {
      r = _lerp(0, 255, (t - 0.33) * 3).round();
      g = _lerp(217, 107, (t - 0.33) * 3).round();
      b = _lerp(255, 157, (t - 0.33) * 3).round();
    } else {
      r = _lerp(255, 108, (t - 0.66) * 3).round();
      g = _lerp(107, 99, (t - 0.66) * 3).round();
      b = _lerp(157, 255, (t - 0.66) * 3).round();
    }

    for (var d = -thickness; d <= thickness; d += 0.5) {
      final px = (x + cos(angle) * d).round();
      final py = (y + sin(angle) * d).round();
      if (px >= 0 && px < size && py >= 0 && py < size) {
        final alpha = ((1.0 - (d.abs() / thickness)) * 40).round().clamp(0, 255);
        _blendPixel(image, px, py, r, g, b, alpha);
      }
    }
  }
}

// Helper functions
double _lerp(double a, double b, double t) => a + (b - a) * t;

void _drawFilledEllipse(img.Image image, int cx, int cy, int rx, int ry, img.Color color) {
  final r = color.r.toInt();
  final g = color.g.toInt();
  final b = color.b.toInt();
  final a = color.a.toInt();

  for (var y = cy - ry; y <= cy + ry; y++) {
    for (var x = cx - rx; x <= cx + rx; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final dx = (x - cx) / rx;
      final dy = (y - cy) / ry;
      final dist = dx * dx + dy * dy;
      if (dist <= 1.0) {
        // Soft edge
        final edgeFade = dist > 0.85 ? (1.0 - (dist - 0.85) / 0.15) : 1.0;
        _blendPixel(image, x, y, r, g, b, (a * edgeFade).round());
      }
    }
  }
}

void _drawFilledCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  _drawFilledEllipse(image, cx, cy, radius, radius, color);
}

void _drawGlowingDot(img.Image image, int cx, int cy, int radius, img.Color color) {
  final r = color.r.toInt();
  final g = color.g.toInt();
  final b = color.b.toInt();
  final a = color.a.toInt();

  for (var y = cy - radius * 2; y <= cy + radius * 2; y++) {
    for (var x = cx - radius * 2; x <= cx + radius * 2; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      if (dist <= radius * 2) {
        final fade = (1.0 - dist / (radius * 2));
        final alpha = (a * fade * fade).round().clamp(0, 255);
        _blendPixel(image, x, y, r, g, b, alpha);
      }
    }
  }
}

void _drawThickLine(img.Image image, int x0, int y0, int x1, int y1, img.Color color, int thickness) {
  final r = color.r.toInt();
  final g = color.g.toInt();
  final b = color.b.toInt();
  final a = color.a.toInt();

  final dx = x1 - x0;
  final dy = y1 - y0;
  final steps = max(dx.abs(), dy.abs());
  if (steps == 0) return;

  for (var i = 0; i <= steps; i++) {
    final x = x0 + (dx * i / steps).round();
    final y = y0 + (dy * i / steps).round();
    for (var ty = -thickness; ty <= thickness; ty++) {
      for (var tx = -thickness; tx <= thickness; tx++) {
        final px = x + tx;
        final py = y + ty;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          _blendPixel(image, px, py, r, g, b, a);
        }
      }
    }
  }
}

void _drawWavyLine(img.Image image, int x0, int x1, int y, int amplitude, img.Color color, int thickness) {
  final r = color.r.toInt();
  final g = color.g.toInt();
  final b = color.b.toInt();
  final a = color.a.toInt();

  for (var x = x0; x <= x1; x++) {
    final t = (x - x0) / (x1 - x0);
    final wavY = y + (sin(t * 3 * pi) * amplitude).round();
    for (var ty = -thickness; ty <= thickness; ty++) {
      final py = wavY + ty;
      if (x >= 0 && x < image.width && py >= 0 && py < image.height) {
        _blendPixel(image, x, py, r, g, b, a);
      }
    }
  }
}

void _blendPixel(img.Image image, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= image.width || y < 0 || y >= image.height) return;
  if (a <= 0) return;

  final existing = image.getPixel(x, y);
  final er = existing.r.toInt();
  final eg = existing.g.toInt();
  final eb = existing.b.toInt();

  final alpha = a / 255.0;
  final nr = (er * (1 - alpha) + r * alpha).round().clamp(0, 255);
  final ng = (eg * (1 - alpha) + g * alpha).round().clamp(0, 255);
  final nb = (eb * (1 - alpha) + b * alpha).round().clamp(0, 255);

  image.setPixelRgba(x, y, nr, ng, nb, 255);
}
