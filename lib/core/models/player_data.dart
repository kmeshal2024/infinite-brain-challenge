import 'dart:convert';
import '../constants/app_constants.dart';

class PlayerData {
  final int coins;
  final int hints;
  final int totalStars;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int currentStreak;
  final int bestStreak;
  final String? lastPlayedDate; // yyyy-MM-dd
  final bool hasCompletedOnboarding;
  final bool hasRemovedAds;
  final DateTime createdAt;

  const PlayerData({
    required this.coins,
    required this.hints,
    required this.totalStars,
    required this.totalGamesPlayed,
    required this.totalGamesWon,
    required this.currentStreak,
    required this.bestStreak,
    this.lastPlayedDate,
    this.hasCompletedOnboarding = false,
    this.hasRemovedAds = false,
    required this.createdAt,
  });

  factory PlayerData.initial() {
    return PlayerData(
      coins: GameConstants.startingCoins,
      hints: GameConstants.startingHints,
      totalStars: 0,
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      currentStreak: 0,
      bestStreak: 0,
      hasCompletedOnboarding: false,
      hasRemovedAds: false,
      createdAt: DateTime.now(),
    );
  }

  PlayerData copyWith({
    int? coins,
    int? hints,
    int? totalStars,
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? currentStreak,
    int? bestStreak,
    String? lastPlayedDate,
    bool? hasCompletedOnboarding,
    bool? hasRemovedAds,
    DateTime? createdAt,
  }) {
    return PlayerData(
      coins: coins ?? this.coins,
      hints: hints ?? this.hints,
      totalStars: totalStars ?? this.totalStars,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasRemovedAds: hasRemovedAds ?? this.hasRemovedAds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'hints': hints,
      'totalStars': totalStars,
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastPlayedDate': lastPlayedDate,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasRemovedAds': hasRemovedAds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      coins: json['coins'] ?? GameConstants.startingCoins,
      hints: json['hints'] ?? GameConstants.startingHints,
      totalStars: json['totalStars'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalGamesWon: json['totalGamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      lastPlayedDate: json['lastPlayedDate'],
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      hasRemovedAds: json['hasRemovedAds'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String encode() => jsonEncode(toJson());
  static PlayerData decode(String source) =>
      PlayerData.fromJson(jsonDecode(source));

  double get winRate {
    if (totalGamesPlayed == 0) return 0;
    return totalGamesWon / totalGamesPlayed;
  }
}
