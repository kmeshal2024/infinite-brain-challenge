import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Enum representing all available mini-games
enum GameType {
  patternMemory,
  numberSequence,
  oddOneOut,
  reactionSpeed,
  shapeLogic,
  quickMath,
  wordMemory,
  colorMatch,
  mathPuzzle24,
  chimpTest,
}

/// Static metadata for each game type
class GameInfo {
  final GameType type;
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final bool isAvailable;

  const GameInfo({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.icon,
    required this.color,
    required this.gradient,
    this.isAvailable = true,
  });

  static final List<GameInfo> allGames = [
    GameInfo(
      type: GameType.patternMemory,
      id: 'pattern_memory',
      name: 'Pattern Memory',
      description: 'Memorize the sequence and repeat it. Tests your visual memory and recall.',
      shortDescription: 'Remember the pattern',
      icon: Icons.grid_view_rounded,
      color: AppColors.memoryColor,
      gradient: const LinearGradient(
        colors: [Color(0xFF7C6FFF), Color(0xFF5B4FDF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.numberSequence,
      id: 'number_sequence',
      name: 'Number Sequence',
      description: 'Find the missing number in the sequence. Tests your logical reasoning.',
      shortDescription: 'Find the pattern',
      icon: Icons.tag_rounded,
      color: AppColors.logicColor,
      gradient: const LinearGradient(
        colors: [Color(0xFF4CC9F0), Color(0xFF3AA8D0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.oddOneOut,
      id: 'odd_one_out',
      name: 'Odd One Out',
      description: 'Spot the different item in the grid. Tests your attention to detail.',
      shortDescription: 'Find what\'s different',
      icon: Icons.search_rounded,
      color: AppColors.patternColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.reactionSpeed,
      id: 'reaction_speed',
      name: 'Reaction Speed',
      description: 'Tap as fast as you can when the signal appears. Tests your reflexes.',
      shortDescription: 'Test your reflexes',
      icon: Icons.bolt_rounded,
      color: AppColors.speedColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFD44444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.shapeLogic,
      id: 'shape_logic',
      name: 'Shape Logic',
      description: 'Complete shape patterns by finding what comes next. Tests your visual logic.',
      shortDescription: 'Complete the pattern',
      icon: Icons.category_rounded,
      color: AppColors.puzzleColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFE879F9), Color(0xFFC026D3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.quickMath,
      id: 'quick_math',
      name: 'Quick Math',
      description: 'Solve math problems under time pressure. Tests your arithmetic speed.',
      shortDescription: 'Solve fast!',
      icon: Icons.calculate_rounded,
      color: AppColors.mathColor,
      gradient: const LinearGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.wordMemory,
      id: 'word_memory',
      name: 'Word Memory',
      description: 'Memorize a list of words, then pick them out from decoys. Tests your verbal memory.',
      shortDescription: 'Remember the words',
      icon: Icons.menu_book_rounded,
      color: AppColors.memoryColor,
      gradient: const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.colorMatch,
      id: 'color_match',
      name: 'Color Match',
      description: 'Does the word match the ink color? A classic Stroop test for your focus.',
      shortDescription: 'Focus under pressure',
      icon: Icons.palette_rounded,
      color: AppColors.speedColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.mathPuzzle24,
      id: 'math_puzzle_24',
      name: 'Math 24',
      description: 'Use all 4 numbers with + − × ÷ to reach 24. Tests your math creativity.',
      shortDescription: 'Reach 24!',
      icon: Icons.extension_rounded,
      color: AppColors.mathColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    GameInfo(
      type: GameType.chimpTest,
      id: 'chimp_test',
      name: 'Chimp Test',
      description: 'Memorize number positions on a grid, then tap them in order. Tests your working memory.',
      shortDescription: 'Tap in order 1 → N',
      icon: Icons.psychology_alt_rounded,
      color: AppColors.memoryColor,
      gradient: const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  static GameInfo getById(String id) {
    return allGames.firstWhere((g) => g.id == id);
  }

  static GameInfo getByType(GameType type) {
    return allGames.firstWhere((g) => g.type == type);
  }
}
