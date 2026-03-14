import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

// ── Service Providers ──────────────────────────────────────────
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

final retentionServiceProvider = Provider<RetentionService>((ref) {
  return RetentionService();
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final difficultyServiceProvider = Provider<DifficultyService>((ref) {
  return DifficultyService();
});

// ── Player Data Provider ───────────────────────────────────────
final playerDataProvider =
    StateNotifierProvider<PlayerDataNotifier, PlayerData>((ref) {
  return PlayerDataNotifier(ref.read(storageServiceProvider));
});

class PlayerDataNotifier extends StateNotifier<PlayerData> {
  final StorageService _storage;

  PlayerDataNotifier(this._storage) : super(PlayerData.initial());

  Future<void> load() async {
    state = await _storage.loadPlayerData();
  }

  Future<void> addCoins(int amount) async {
    state = state.copyWith(coins: state.coins + amount);
    await _storage.savePlayerData(state);
  }

  Future<void> spendCoins(int amount) async {
    if (state.coins >= amount) {
      state = state.copyWith(coins: state.coins - amount);
      await _storage.savePlayerData(state);
    }
  }

  Future<void> useHint() async {
    if (state.hints > 0) {
      state = state.copyWith(hints: state.hints - 1);
      await _storage.savePlayerData(state);
    }
  }

  Future<void> addHints(int amount) async {
    state = state.copyWith(hints: state.hints + amount);
    await _storage.savePlayerData(state);
  }

  Future<void> recordGameResult(GameResult result) async {
    final newGamesPlayed = state.totalGamesPlayed + 1;
    final newGamesWon = result.isWin ? state.totalGamesWon + 1 : state.totalGamesWon;
    final newStars = state.totalStars + result.stars;
    final newCoins = state.coins + result.coinsEarned;

    state = state.copyWith(
      totalGamesPlayed: newGamesPlayed,
      totalGamesWon: newGamesWon,
      totalStars: newStars,
      coins: newCoins,
    );
    await _storage.savePlayerData(state);
  }

  Future<void> updateStreak() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    int newStreak;
    if (state.lastPlayedDate == yesterday) {
      newStreak = state.currentStreak + 1;
    } else if (state.lastPlayedDate == today) {
      newStreak = state.currentStreak; // Already played today
    } else {
      newStreak = 1; // Streak broken, restart
    }

    final newBestStreak =
        newStreak > state.bestStreak ? newStreak : state.bestStreak;

    state = state.copyWith(
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      lastPlayedDate: today,
    );
    await _storage.savePlayerData(state);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    await _storage.savePlayerData(state);
    await _storage.setOnboardingComplete();
  }

  Future<void> removeAds() async {
    state = state.copyWith(hasRemovedAds: true);
    await _storage.savePlayerData(state);
  }
}

// ── Game Progress Provider ─────────────────────────────────────
final gameProgressProvider = StateNotifierProvider.family<
    GameProgressNotifier, GameProgress, String>((ref, gameId) {
  return GameProgressNotifier(ref.read(storageServiceProvider), gameId);
});

class GameProgressNotifier extends StateNotifier<GameProgress> {
  final StorageService _storage;
  final String gameId;

  GameProgressNotifier(this._storage, this.gameId)
      : super(GameProgress(gameId: gameId));

  Future<void> load() async {
    state = await _storage.loadGameProgress(gameId);
  }

  Future<void> recordLevelResult(LevelResult result) async {
    final existing = state.levelResults[result.level];
    final updatedResults = Map<int, LevelResult>.from(state.levelResults);

    // Only update if new result is better
    if (existing == null || result.stars > existing.stars) {
      updatedResults[result.level] = result;
    }

    // Calculate total stars
    int totalStars = 0;
    for (final lr in updatedResults.values) {
      totalStars += lr.stars;
    }

    // Unlock next level
    final nextLevel = result.level + 1;
    final highestUnlocked = nextLevel > state.highestLevelUnlocked
        ? nextLevel
        : state.highestLevelUnlocked;

    final bestScore =
        result.score > state.bestScore ? result.score : state.bestScore;

    state = state.copyWith(
      levelResults: updatedResults,
      highestLevelUnlocked: highestUnlocked,
      totalStarsEarned: totalStars,
      bestScore: bestScore,
    );

    await _storage.saveGameProgress(state);
  }
}

// ── Settings Provider ──────────────────────────────────────────
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final StorageService _storage;

  SettingsNotifier(this._storage)
      : super({
          'soundEnabled': true,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
        });

  Future<void> load() async {
    state = await _storage.loadSettings();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final updated = Map<String, dynamic>.from(state);
    updated[key] = value;
    state = updated;
    await _storage.saveSettings(state);
  }

  bool get soundEnabled => state['soundEnabled'] ?? true;
  bool get vibrationEnabled => state['vibrationEnabled'] ?? true;
  bool get notificationsEnabled => state['notificationsEnabled'] ?? true;
}
