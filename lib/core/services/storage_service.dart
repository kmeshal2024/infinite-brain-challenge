import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/player_data.dart';
import '../models/game_progress.dart';
import '../models/game_result.dart';

/// Handles all local persistence using SharedPreferences.
/// For MVP, this is sufficient. Hive can replace for heavier data later.
class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Player Data ──
  Future<PlayerData> loadPlayerData() async {
    final raw = _prefs.getString(StorageKeys.playerData);
    if (raw == null) {
      final initial = PlayerData.initial();
      await savePlayerData(initial);
      return initial;
    }
    return PlayerData.decode(raw);
  }

  Future<void> savePlayerData(PlayerData data) async {
    await _prefs.setString(StorageKeys.playerData, data.encode());
  }

  // ── Game Progress ──
  Future<GameProgress> loadGameProgress(String gameId) async {
    final key = '${StorageKeys.gameProgress}_$gameId';
    final raw = _prefs.getString(key);
    if (raw == null) {
      return GameProgress(gameId: gameId);
    }
    return GameProgress.decode(raw);
  }

  Future<void> saveGameProgress(GameProgress progress) async {
    final key = '${StorageKeys.gameProgress}_${progress.gameId}';
    await _prefs.setString(key, progress.encode());
  }

  // ── Daily Challenge ──
  Future<DailyChallenge?> loadDailyChallenge(String date) async {
    final key = '${StorageKeys.dailyChallenge}_$date';
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DailyChallenge.fromJson(jsonDecode(raw));
  }

  Future<void> saveDailyChallenge(DailyChallenge challenge) async {
    final key = '${StorageKeys.dailyChallenge}_${challenge.date}';
    await _prefs.setString(key, jsonEncode(challenge.toJson()));
  }

  // ── Settings ──
  Future<Map<String, dynamic>> loadSettings() async {
    final raw = _prefs.getString(StorageKeys.settings);
    if (raw == null) return Map<String, dynamic>.from(_defaultSettings);
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(StorageKeys.settings, jsonEncode(settings));
  }

  static const Map<String, dynamic> _defaultSettings = {
    'soundEnabled': true,
    'vibrationEnabled': true,
    'notificationsEnabled': true,
  };

  // ── Onboarding ──
  bool get hasCompletedOnboarding =>
      _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(StorageKeys.onboardingComplete, true);
  }

  // ── Clear All ──
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
