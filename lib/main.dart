import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/review_service.dart';
import 'core/providers/app_providers.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for premium dark look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0F1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize audio service
  final audioService = AudioService();
  await audioService.init();

  // Initialize AppLovin MAX ads
  final adService = AdService();
  await adService.init();

  // Initialize review service (tracks in-app review eligibility)
  final reviewService = ReviewService();
  await reviewService.init();

  runApp(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(audioService),
        adServiceProvider.overrideWithValue(adService),
        reviewServiceProvider.overrideWithValue(reviewService),
      ],
      child: const InfiniteBrainApp(),
    ),
  );
}

class InfiniteBrainApp extends StatelessWidget {
  const InfiniteBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Infinite Brain Challenge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
