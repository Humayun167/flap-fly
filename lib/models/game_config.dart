// lib/models/game_config.dart

class LevelConfig {
  final int level;
  final double gravity;
  final double pipeSpeed;
  final double pipeGap;
  final double pipeInterval;
  final String name;
  final int scoreToUnlock;

  const LevelConfig({
    required this.level,
    required this.gravity,
    required this.pipeSpeed,
    required this.pipeGap,
    required this.pipeInterval,
    required this.name,
    required this.scoreToUnlock,
  });
}

class GameConfig {
  static const double birdX = -0.3;
  static const double birdSize = 0.08;
  static const double pipeWidth = 0.2;

  // Coin system
  static const int coinsPerPipe = 1;
  static const int coinsPerStar = 3;
  static const int reviveCost = 5;

  static const List<LevelConfig> levels = [
    LevelConfig(
      level: 1,
      gravity: 0.0035,
      pipeSpeed: 0.012,
      pipeGap: 0.55,
      pipeInterval: 2.8,
      name: 'Easy',
      scoreToUnlock: 0,
    ),
    LevelConfig(
      level: 2,
      gravity: 0.0045,
      pipeSpeed: 0.016,
      pipeGap: 0.48,
      pipeInterval: 2.5,
      name: 'Medium',
      scoreToUnlock: 5,
    ),
    LevelConfig(
      level: 3,
      gravity: 0.0055,
      pipeSpeed: 0.020,
      pipeGap: 0.40,
      pipeInterval: 2.2,
      name: 'Hard',
      scoreToUnlock: 15,
    ),
  ];

  static LevelConfig getLevel(int level) {
    return levels[level.clamp(0, levels.length - 1)];
  }
}

class GameState {
  static const String idle = 'idle';
  static const String playing = 'playing';
  static const String paused = 'paused';
  static const String dead = 'dead';
  static const String levelUp = 'levelUp';
}
