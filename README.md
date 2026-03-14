# Infinite Brain Challenge

Flutter brain-training game. 39 Dart files, 4 playable mini-games.

## Exact Setup Steps (clean machine)

Prerequisites: Flutter SDK 3.2+ installed and on PATH.

```bash
# 1. Create empty project directory
mkdir infinite_brain_challenge && cd infinite_brain_challenge

# 2. Extract this project's files into it
#    (copy lib/, pubspec.yaml, assets/, analysis_options.yaml, setup.sh)

# 3. Generate platform scaffolding (Android + iOS)
flutter create --org com.infinitebrain --project-name infinite_brain_challenge .

# 4. Get dependencies
flutter pub get

# 5. Run on connected device or emulator
flutter run
```

Step 3 (`flutter create .`) will generate these files/directories automatically:
- `android/` (entire directory - gradle, manifest, MainActivity)
- `ios/` (entire directory - Xcode project, podfile)
- `test/` (widget test scaffold)
- `web/` (if web is enabled)
- `.metadata`
- `infinite_brain_challenge.iml`

It will NOT overwrite:
- `lib/` (your code)
- `pubspec.yaml` (your dependencies)
- `assets/` (your assets)
- `analysis_options.yaml`

## Files You Must Provide

Everything is included in this project. Nothing needs manual creation.
The `assets/images/` and `assets/sounds/` directories contain placeholder README.txt files
so Flutter's asset bundler recognizes them. Sound effects are no-op stubs until you add
actual .mp3 files.

## What Each Dependency Does

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.4.9 | State management (player data, game progress, settings) |
| go_router | ^13.0.0 | Declarative routing with path params for game/level URLs |
| shared_preferences | ^2.2.2 | Local persistence (player data, progress, settings) |
| google_fonts | ^6.1.0 | Nunito font loaded at runtime (no font files needed) |
| intl | ^0.19.0 | DateFormat for streak date tracking |

## Architecture

```
lib/
├── main.dart                          # Entry point, ProviderScope, MaterialApp.router
├── routing/app_router.dart            # GoRouter with all routes
├── core/
│   ├── constants/app_constants.dart   # Game config, routes, storage keys
│   ├── models/                        # PlayerData, GameProgress, GameResult, GameType
│   ├── providers/app_providers.dart   # Riverpod: playerData, gameProgress, settings
│   ├── services/                      # StorageService, AudioService, AdService, AnalyticsService
│   ├── theme/                         # AppColors, AppSpacing, AppRadius, AppTypography, AppTheme
│   └── widgets/                       # GameButton, PremiumCard, GameHUD, CoinDisplay, StarDisplay
├── features/                          # Screen-per-folder: splash, onboarding, home, etc.
└── games/
    ├── common/mini_game_controller.dart  # Shared mixin: scoring, timing, star calc
    ├── pattern_memory/                   # Fully playable
    ├── number_sequence/                  # Fully playable
    ├── odd_one_out/                      # Fully playable
    └── reaction_speed/                   # Fully playable
```

## Navigation Flow

```
Splash → (checks onboarding) → Onboarding or Home
Home → Game Selection → Level Selection → Gameplay → Results
Home → Daily Challenge → Gameplay → Results
Home → Profile | Shop | Settings
```

## Known Limitations

- AudioService methods are no-op stubs (add audioplayers dep + .mp3 files)
- AdService returns mock success (add google_mobile_ads dep + real ad unit IDs)
- AnalyticsService prints to console (add firebase_analytics dep)
- Daily challenge completion is not persisted across sessions yet
- No app icon configured (use flutter_launcher_icons)
- No native splash screen (use flutter_native_splash)
