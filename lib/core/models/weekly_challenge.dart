import 'dart:math';
import 'game_type.dart';

/// Weekly challenge that resets every Monday
class WeeklyChallenge {
  final String weekId; // yyyy-Www (e.g., 2026-W12)
  final List<WeeklyTask> tasks;
  final int totalXpReward;
  final int totalCoinReward;

  const WeeklyChallenge({
    required this.weekId,
    required this.tasks,
    this.totalXpReward = 200,
    this.totalCoinReward = 150,
  });

  bool get isComplete => tasks.every((t) => t.isComplete);
  int get completedCount => tasks.where((t) => t.isComplete).length;
  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'totalXpReward': totalXpReward,
        'totalCoinReward': totalCoinReward,
      };

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      weekId: json['weekId'] ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => WeeklyTask.fromJson(t))
              .toList() ??
          [],
      totalXpReward: json['totalXpReward'] ?? 200,
      totalCoinReward: json['totalCoinReward'] ?? 150,
    );
  }

  /// Generate a weekly challenge based on week ID
  factory WeeklyChallenge.generate(String weekId) {
    final rng = Random(weekId.hashCode);
    final availableGames =
        GameInfo.allGames.where((g) => g.isAvailable).toList();

    final tasks = <WeeklyTask>[
      WeeklyTask(
        id: 'weekly_levels',
        description: 'Complete 15 levels this week',
        target: 15,
        type: WeeklyTaskType.completeLevels,
      ),
      WeeklyTask(
        id: 'weekly_perfect',
        description: 'Get 5 perfect scores',
        target: 5,
        type: WeeklyTaskType.perfectScores,
      ),
      WeeklyTask(
        id: 'weekly_daily',
        description: 'Complete 3 daily challenges',
        target: 3,
        type: WeeklyTaskType.dailyChallenges,
      ),
      WeeklyTask(
        id: 'weekly_game',
        description:
            'Play 10 rounds of ${availableGames[rng.nextInt(availableGames.length)].name}',
        target: 10,
        type: WeeklyTaskType.playSpecificGame,
        gameId: availableGames[rng.nextInt(availableGames.length)].id,
      ),
      WeeklyTask(
        id: 'weekly_stars',
        description: 'Earn 20 stars',
        target: 20,
        type: WeeklyTaskType.earnStars,
      ),
    ];

    return WeeklyChallenge(weekId: weekId, tasks: tasks);
  }
}

enum WeeklyTaskType {
  completeLevels,
  perfectScores,
  dailyChallenges,
  playSpecificGame,
  earnStars,
}

class WeeklyTask {
  final String id;
  final String description;
  final int target;
  final int current;
  final WeeklyTaskType type;
  final String? gameId;

  const WeeklyTask({
    required this.id,
    required this.description,
    required this.target,
    this.current = 0,
    required this.type,
    this.gameId,
  });

  bool get isComplete => current >= target;
  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  WeeklyTask copyWith({int? current}) {
    return WeeklyTask(
      id: id,
      description: description,
      target: target,
      current: current ?? this.current,
      type: type,
      gameId: gameId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'target': target,
        'current': current,
        'type': type.name,
        'gameId': gameId,
      };

  factory WeeklyTask.fromJson(Map<String, dynamic> json) {
    return WeeklyTask(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      target: json['target'] ?? 0,
      current: json['current'] ?? 0,
      type: WeeklyTaskType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WeeklyTaskType.completeLevels,
      ),
      gameId: json['gameId'],
    );
  }
}
