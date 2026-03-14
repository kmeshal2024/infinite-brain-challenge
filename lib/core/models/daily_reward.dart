/// Daily login reward calendar
class DailyReward {
  final int day; // 1-7
  final int coins;
  final int xp;
  final int hints;
  final bool isBonusDay; // day 7 is always bonus
  final String label;

  const DailyReward({
    required this.day,
    this.coins = 0,
    this.xp = 0,
    this.hints = 0,
    this.isBonusDay = false,
    this.label = '',
  });
}

/// 7-day reward cycle
class DailyRewardCalendar {
  DailyRewardCalendar._();

  static const List<DailyReward> rewards = [
    DailyReward(day: 1, coins: 10, xp: 25, label: '10 Coins'),
    DailyReward(day: 2, coins: 15, xp: 25, label: '15 Coins'),
    DailyReward(day: 3, hints: 1, xp: 25, label: '1 Hint'),
    DailyReward(day: 4, coins: 25, xp: 25, label: '25 Coins'),
    DailyReward(day: 5, coins: 30, xp: 30, label: '30 Coins'),
    DailyReward(day: 6, hints: 2, xp: 30, label: '2 Hints'),
    DailyReward(
      day: 7,
      coins: 100,
      xp: 50,
      hints: 1,
      isBonusDay: true,
      label: 'Mega Bonus!',
    ),
  ];

  static DailyReward getReward(int streakDay) {
    // Cycle through 7 days
    final dayIndex = ((streakDay - 1) % 7);
    return rewards[dayIndex];
  }
}

/// Tracks the player's daily reward state
class DailyRewardState {
  final String lastClaimDate; // yyyy-MM-dd
  final int consecutiveDays;
  final bool claimedToday;

  const DailyRewardState({
    this.lastClaimDate = '',
    this.consecutiveDays = 0,
    this.claimedToday = false,
  });

  DailyRewardState copyWith({
    String? lastClaimDate,
    int? consecutiveDays,
    bool? claimedToday,
  }) {
    return DailyRewardState(
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      claimedToday: claimedToday ?? this.claimedToday,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastClaimDate': lastClaimDate,
        'consecutiveDays': consecutiveDays,
        'claimedToday': claimedToday,
      };

  factory DailyRewardState.fromJson(Map<String, dynamic> json) {
    return DailyRewardState(
      lastClaimDate: json['lastClaimDate'] ?? '',
      consecutiveDays: json['consecutiveDays'] ?? 0,
      claimedToday: json['claimedToday'] ?? false,
    );
  }
}
