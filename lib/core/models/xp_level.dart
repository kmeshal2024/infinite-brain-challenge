/// XP / Player Level progression system
class XpLevel {
  XpLevel._();

  /// XP thresholds for each level
  static const List<int> _thresholds = [
    0,     // Level 1
    200,   // Level 2
    500,   // Level 3
    900,   // Level 4
    1400,  // Level 5
    2000,  // Level 6
    2700,  // Level 7
    3500,  // Level 8
    4500,  // Level 9
    5700,  // Level 10
    7000,  // Level 11
    8500,  // Level 12
    10200, // Level 13
    12000, // Level 14
    14000, // Level 15
    16200, // Level 16
    18600, // Level 17
    21200, // Level 18
    24000, // Level 19
    27000, // Level 20
    30500, // Level 21
    34500, // Level 22
    39000, // Level 23
    44000, // Level 24
    50000, // Level 25 — Brain Master
  ];

  static const int maxLevel = 25;

  /// Get the level for a given total XP
  static int levelForXp(int totalXp) {
    for (var i = _thresholds.length - 1; i >= 0; i--) {
      if (totalXp >= _thresholds[i]) return i + 1;
    }
    return 1;
  }

  /// XP needed to reach the next level
  static int xpForNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return _thresholds[currentLevel]; // next level's threshold
  }

  /// XP threshold for current level
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > maxLevel) return _thresholds.last;
    return _thresholds[level - 1];
  }

  /// Progress to next level (0.0 - 1.0)
  static double progressToNextLevel(int totalXp) {
    final level = levelForXp(totalXp);
    if (level >= maxLevel) return 1.0;
    final currentThreshold = _thresholds[level - 1];
    final nextThreshold = _thresholds[level];
    final range = nextThreshold - currentThreshold;
    if (range <= 0) return 1.0;
    return ((totalXp - currentThreshold) / range).clamp(0.0, 1.0);
  }

  /// Level title
  static String titleForLevel(int level) {
    if (level <= 3) return 'Beginner';
    if (level <= 6) return 'Learner';
    if (level <= 9) return 'Thinker';
    if (level <= 12) return 'Sharp Mind';
    if (level <= 15) return 'Brain Pro';
    if (level <= 18) return 'Genius';
    if (level <= 21) return 'Mastermind';
    if (level <= 24) return 'Brain Legend';
    return 'Brain Master';
  }

  /// XP sources
  static const int xpPerLevelComplete = 50;
  static const int xpPerPerfectLevel = 100;
  static const int xpPerDailyChallenge = 75;
  static const int xpPerDailyLogin = 25;
  static const int xpPerAchievement = 50;
  static const int xpPer3StarLevel = 30; // bonus for 3 stars
}
