// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates a 1024x500 feature graphic for Google Play Store.
/// Run with: dart run tool/generate_feature_graphic.dart
void main() {
  print('Generating feature graphic (1024x500)...');

  final width = 1024;
  final height = 500;
  final image = img.Image(width: width, height: height);

  // Dark gradient background matching app theme
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final t = y / height;
      final r = (13 + (22 - 13) * t).round();
      final g = (15 + (22 - 15) * t).round();
      final b = (26 + (40 - 26) * t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Primary accent glow (center-right, blue/purple)
  _drawGlow(image, 620, 250, 300, 76, 124, 247, 0.15);
  _drawGlow(image, 400, 260, 280, 124, 111, 255, 0.10);

  // Gold accent glow (left area)
  _drawGlow(image, 250, 200, 200, 255, 215, 0, 0.06);

  // Draw brain icon (centered)
  _drawBrainShape(image, 512, 200, 80);

  // Draw "INFINITE BRAIN CHALLENGE" text area
  // Since we can't render fonts with the image package,
  // we draw a prominent text placeholder area
  _drawTextBlock(image, 512, 360, 'title');
  _drawTextBlock(image, 512, 420, 'subtitle');

  // Draw 4 game icons along the bottom
  final gameColors = [
    [124, 111, 255], // Pattern Memory - purple
    [76, 201, 240],  // Number Sequence - cyan
    [255, 107, 107], // Odd One Out - coral
    [74, 222, 128],  // Reaction Speed - green
  ];

  for (int i = 0; i < 4; i++) {
    final cx = 280 + i * 150;
    final cy = 440;
    _drawGamePill(image, cx, cy, gameColors[i][0], gameColors[i][1], gameColors[i][2]);
  }

  // Corner accents
  _drawCornerDots(image);

  // Save
  final outputDir = Directory('assets/store');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  final outputPath = 'assets/store/feature_graphic.png';
  File(outputPath).writeAsBytesSync(img.encodePng(image));
  print('Feature graphic saved to $outputPath');
  print('Size: 1024x500 pixels');
  print('');
  print('NOTE: This is a programmatically generated placeholder.');
  print('For best results, overlay text in a graphic editor:');
  print('  Line 1: "INFINITE BRAIN CHALLENGE" (white, bold, 48px)');
  print('  Line 2: "4 Brain-Training Games" (light gray, 24px)');
}

void _drawGlow(img.Image image, int cx, int cy, int radius, int r, int g, int b, double maxAlpha) {
  for (int y = cy - radius; y < cy + radius; y++) {
    for (int x = cx - radius; x < cx + radius; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final dist = _distance(x, y, cx, cy);
      if (dist > radius) continue;
      final alpha = maxAlpha * (1.0 - dist / radius);
      final existing = image.getPixel(x, y);
      final er = existing.r.toInt();
      final eg = existing.g.toInt();
      final eb = existing.b.toInt();
      image.setPixelRgba(x, y,
        (er + (r - er) * alpha).round().clamp(0, 255),
        (eg + (g - eg) * alpha).round().clamp(0, 255),
        (eb + (b - eb) * alpha).round().clamp(0, 255),
        255,
      );
    }
  }
}

void _drawBrainShape(img.Image image, int cx, int cy, int size) {
  // Left hemisphere
  _drawFilledCircle(image, cx - 25, cy, size ~/ 2 + 10, 76, 124, 247, 0.6);
  _drawFilledCircle(image, cx - 35, cy - 15, size ~/ 3, 100, 140, 255, 0.5);

  // Right hemisphere
  _drawFilledCircle(image, cx + 25, cy, size ~/ 2 + 10, 124, 111, 255, 0.6);
  _drawFilledCircle(image, cx + 35, cy - 15, size ~/ 3, 140, 130, 255, 0.5);

  // Center connection
  _drawFilledCircle(image, cx, cy + 5, size ~/ 4, 90, 118, 245, 0.7);

  // Neural dots
  final dots = [
    [cx - 40, cy - 30], [cx + 40, cy - 30],
    [cx - 20, cy - 45], [cx + 20, cy - 45],
    [cx - 50, cy + 10], [cx + 50, cy + 10],
    [cx, cy - 50],
  ];
  for (final dot in dots) {
    _drawFilledCircle(image, dot[0], dot[1], 4, 255, 255, 255, 0.8);
  }
}

void _drawTextBlock(img.Image image, int cx, int cy, String type) {
  // Draw a subtle highlight bar where text would go
  final w = type == 'title' ? 460 : 280;
  final h = type == 'title' ? 36 : 20;
  for (int y = cy - h ~/ 2; y < cy + h ~/ 2; y++) {
    for (int x = cx - w ~/ 2; x < cx + w ~/ 2; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final existing = image.getPixel(x, y);
      final alpha = type == 'title' ? 0.25 : 0.12;
      image.setPixelRgba(x, y,
        (existing.r.toInt() + (255 - existing.r.toInt()) * alpha).round().clamp(0, 255),
        (existing.g.toInt() + (255 - existing.g.toInt()) * alpha).round().clamp(0, 255),
        (existing.b.toInt() + (255 - existing.b.toInt()) * alpha).round().clamp(0, 255),
        255,
      );
    }
  }
}

void _drawGamePill(img.Image image, int cx, int cy, int r, int g, int b) {
  _drawFilledCircle(image, cx, cy, 18, r, g, b, 0.35);
  _drawFilledCircle(image, cx, cy, 10, r, g, b, 0.6);
  _drawFilledCircle(image, cx, cy, 5, 255, 255, 255, 0.5);
}

void _drawCornerDots(img.Image image) {
  // Subtle decorative dots in corners
  final positions = [
    [40, 40], [80, 30], [30, 80],
    [984, 40], [944, 30], [994, 80],
    [40, 460], [80, 470], [30, 420],
    [984, 460], [944, 470], [994, 420],
  ];
  for (final pos in positions) {
    _drawFilledCircle(image, pos[0], pos[1], 3, 76, 124, 247, 0.2);
  }
}

void _drawFilledCircle(img.Image image, int cx, int cy, int radius, int r, int g, int b, double alpha) {
  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      if (_distance(x, y, cx, cy) <= radius) {
        final existing = image.getPixel(x, y);
        image.setPixelRgba(x, y,
          (existing.r.toInt() + (r - existing.r.toInt()) * alpha).round().clamp(0, 255),
          (existing.g.toInt() + (g - existing.g.toInt()) * alpha).round().clamp(0, 255),
          (existing.b.toInt() + (b - existing.b.toInt()) * alpha).round().clamp(0, 255),
          255,
        );
      }
    }
  }
}

double _distance(int x1, int y1, int x2, int y2) {
  final dx = (x1 - x2).toDouble();
  final dy = (y1 - y2).toDouble();
  return (dx * dx + dy * dy) > 0 ? (dx * dx + dy * dy).toDouble() == 0 ? 0 : _sqrt(dx * dx + dy * dy) : 0;
}

double _sqrt(double v) {
  double x = v / 2;
  for (int i = 0; i < 20; i++) {
    x = (x + v / x) / 2;
  }
  return x;
}
