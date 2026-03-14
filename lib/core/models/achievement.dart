import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Achievement definition and tracking
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;
  final int target; // target value to unlock
  final int xpReward;
  final int coinReward;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.target,
    this.xpReward = 50,
    this.coinReward = 25,
  });
}

enum AchievementCategory { gameplay, collection, streak, mastery, special }

/// Player's achievement progress
class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievementId,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  AchievementProgress copyWith({
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'currentValue': currentValue,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] ?? '',
      currentValue: json['currentValue'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

/// All achievements in the game
class Achievements {
  Achievements._();

  static const List<Achievement> all = [
    // Gameplay
    Achievement(
      id: 'first_win',
      name: 'First Win',
      description: 'Complete your first level',
      icon: Icons.emoji_events_rounded,
      color: AppColors.gold,
      category: AchievementCategory.gameplay,
      target: 1,
      coinReward: 50,
    ),
    Achievement(
      id: 'ten_wins',
      name: 'Getting Started',
      description: 'Complete 10 levels',
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
      category: AchievementCategory.gameplay,
      target: 10,
    ),
    Achievement(
      id: 'fifty_wins',
      name: 'Brain Athlete',
      description: 'Complete 50 levels',
      icon: Icons.fitness_center_rounded,
      color: AppColors.primary,
      category: AchievementCategory.gameplay,
      target: 50,
      coinReward: 100,
    ),
    Achievement(
      id: 'hundred_wins',
      name: 'Centurion',
      description: 'Complete 100 levels',
      icon: Icons.military_tech_rounded,
      color: AppColors.puzzleColor,
      category: AchievementCategory.gameplay,
      target: 100,
      coinReward: 200,
    ),

    // Perfect scores
    Achievement(
      id: 'perfect_memory',
      name: 'Perfect Memory',
      description: 'Get a perfect score in Pattern Memory',
      icon: Icons.grid_view_rounded,
      color: AppColors.memoryColor,
      category: AchievementCategory.mastery,
      target: 1,
    ),
    Achievement(
      id: 'perfect_logic',
      name: 'Logic Master',
      description: 'Get a perfect score in Number Sequence',
      icon: Icons.tag_rounded,
      color: AppColors.logicColor,
      category: AchievementCategory.mastery,
      target: 1,
    ),
    Achievement(
      id: 'perfect_spotter',
      name: 'Eagle Eye',
      description: 'Get a perfect score in Odd One Out',
      icon: Icons.search_rounded,
      color: AppColors.patternColor,
      category: AchievementCategory.mastery,
      target: 1,
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'React under 200ms in Reaction Speed',
      icon: Icons.bolt_rounded,
      color: AppColors.speedColor,
      category: AchievementCategory.mastery,
      target: 1,
    ),

    // Collection
    Achievement(
      id: 'coins_100',
      name: 'Coin Collector',
      description: 'Earn 100 coins total',
      icon: Icons.monetization_on_rounded,
      color: AppColors.gold,
      category: AchievementCategory.collection,
      target: 100,
    ),
    Achievement(
      id: 'coins_1000',
      name: 'Gold Hoarder',
      description: 'Earn 1,000 coins total',
      icon: Icons.savings_rounded,
      color: AppColors.goldDark,
      category: AchievementCategory.collection,
      target: 1000,
      coinReward: 100,
    ),
    Achievement(
      id: 'stars_50',
      name: 'Star Gazer',
      description: 'Earn 50 stars',
      icon: Icons.star_rounded,
      color: AppColors.gold,
      category: AchievementCategory.collection,
      target: 50,
    ),
    Achievement(
      id: 'stars_200',
      name: 'Constellation',
      description: 'Earn 200 stars',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primaryLight,
      category: AchievementCategory.collection,
      target: 200,
      coinReward: 150,
    ),

    // Streaks
    Achievement(
      id: 'streak_3',
      name: 'On a Roll',
      description: 'Maintain a 3-day streak',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.accent,
      category: AchievementCategory.streak,
      target: 3,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.warning,
      category: AchievementCategory.streak,
      target: 7,
      coinReward: 100,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      icon: Icons.whatshot_rounded,
      color: AppColors.error,
      category: AchievementCategory.streak,
      target: 30,
      coinReward: 500,
    ),

    // Special
    Achievement(
      id: 'daily_5',
      name: 'Daily Devotee',
      description: 'Complete 5 daily challenges',
      icon: Icons.calendar_today_rounded,
      color: AppColors.logicColor,
      category: AchievementCategory.special,
      target: 5,
    ),
    Achievement(
      id: 'all_games',
      name: 'Well Rounded',
      description: 'Complete a level in all 4 games',
      icon: Icons.category_rounded,
      color: AppColors.puzzleColor,
      category: AchievementCategory.special,
      target: 4,
      coinReward: 100,
    ),
    Achievement(
      id: 'level_10',
      name: 'Brain Explorer',
      description: 'Reach player level 10',
      icon: Icons.psychology_rounded,
      color: AppColors.primary,
      category: AchievementCategory.special,
      target: 10,
      coinReward: 200,
    ),
  ];

  static Achievement getById(String id) {
    return all.firstWhere((a) => a.id == id);
  }
}
