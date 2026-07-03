// lib/screens/game_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_config.dart';
import '../models/pipe.dart';
import '../audio/audio_manager.dart';
import '../services/purchase_service.dart';
import '../widgets/bird_widget.dart';
import '../widgets/pipe_widget.dart';
import '../widgets/background_widget.dart';
import 'coin_shop_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Bird state
  double _birdY = 0.0;
  double _birdVelocity = 0.0;
  double _birdRotation = 0.0;

  // Game state
  String _gameState = GameState.idle;
  int _score = 0;
  int _highScore = 0;
  int _currentLevel = 0;
  int _selectedStartLevel = 0;
  String _stateBeforeOptions = GameState.idle;
  final List<Pipe> _pipes = [];
  final List<_BonusStar> _bonusStars = [];
  double _pipeTimer = 0;
  double _groundOffset = 0;

  // Coin system
  int _coins = 0;
  bool _hasUsedRevive = false;

  // Animation
  late AnimationController _gameLoopController;
  late AnimationController _deathAnimController;
  late AnimationController _levelUpController;
  late Animation<double> _levelUpAnim;
  late AnimationController _idlePulseController;
  late Animation<double> _idlePulseAnim;

  // Services
  final AudioManager _audio = AudioManager();
  final PurchaseService _purchaseService = PurchaseService();
  final Random _random = Random();

  LevelConfig get _level => GameConfig.getLevel(_currentLevel);

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initPurchases();

    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )..addListener(_gameLoop);

    _deathAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _levelUpAnim = CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.elasticOut,
    );

    _idlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _idlePulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _idlePulseController, curve: Curves.easeInOut),
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _initPurchases() {
    _purchaseService.initialize();
    _purchaseService.onCoinsDelivered = (coins) {
      setState(() => _coins += coins);
      _saveCoins();
    };
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('high_score') ?? 0;
      _selectedStartLevel = prefs.getInt('start_level') ?? 0;
      _selectedStartLevel =
          _selectedStartLevel.clamp(0, GameConfig.levels.length - 1);
      _coins = prefs.getInt('coins') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', _highScore);
    }
  }

  Future<void> _saveStartLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_level', level);
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
  }

  Future<void> _resetHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('high_score');
    if (mounted) {
      setState(() => _highScore = 0);
    }
  }

  void _gameLoop() {
    if (_gameState != GameState.playing) return;

    setState(() {
      // Bird physics
      _birdVelocity += _level.gravity;
      _birdY += _birdVelocity;
      _birdRotation = (_birdVelocity * 4).clamp(-0.5, 1.2);

      // Ground scrolling
      _groundOffset = (_groundOffset + _level.pipeSpeed) % 1.0;

      // Pipe spawning
      _pipeTimer += _level.pipeSpeed;
      if (_pipeTimer >= _level.pipeInterval) {
        _pipeTimer = 0;
        _spawnPipe();
      }

      // Update pipes
      for (var pipe in _pipes) {
        pipe.x -= _level.pipeSpeed;
      }
      _pipes.removeWhere((p) => p.x < -1.2);

      for (var star in _bonusStars) {
        star.x -= _level.pipeSpeed;
      }
      _bonusStars.removeWhere((s) => s.x < -1.2 || s.collected);

      // Score & level check
      for (var pipe in _pipes) {
        if (!pipe.passed && pipe.x < GameConfig.birdX - 0.05) {
          pipe.passed = true;
          _score++;
          _coins += GameConfig.coinsPerPipe;
          _audio.playScore();
          _checkLevelUp();
          _saveCoins();
        }
      }

      _checkBonusCollection();

      // Collision detection
      if (_checkCollision()) {
        _triggerDeath();
      }
    });
  }

  void _spawnPipe() {
    final topHeight = 0.15 + _random.nextDouble() * 0.4;
    _pipes.add(Pipe(x: 1.3, topHeight: topHeight));

    if (_random.nextDouble() < 0.35) {
      final gapTop = topHeight * 2 - 1;
      final margin = 0.09;
      final availableGap = max(0.0, _level.pipeGap - margin * 2);
      final starY = gapTop + margin + _random.nextDouble() * availableGap;
      _bonusStars.add(_BonusStar(x: 1.3, y: starY));
    }
  }

  void _checkBonusCollection() {
    final birdLeft = GameConfig.birdX - GameConfig.birdSize / 2;
    final birdRight = GameConfig.birdX + GameConfig.birdSize / 2;
    final birdTop = _birdY - GameConfig.birdSize / 2;
    final birdBottom = _birdY + GameConfig.birdSize / 2;

    for (var star in _bonusStars) {
      if (star.collected) continue;

      final starLeft = star.x - _BonusStar.size / 2;
      final starRight = star.x + _BonusStar.size / 2;
      final starTop = star.y - _BonusStar.size / 2;
      final starBottom = star.y + _BonusStar.size / 2;

      final overlaps = birdRight > starLeft &&
          birdLeft < starRight &&
          birdBottom > starTop &&
          birdTop < starBottom;

      if (overlaps) {
        star.collected = true;
        _score += 2;
        _coins += GameConfig.coinsPerStar;
        _audio.playScore();
        _checkLevelUp();
        _saveCoins();
      }
    }
  }

  bool _checkCollision() {
    // Ground and ceiling
    if (_birdY > 0.85 || _birdY < -0.95) return true;

    final birdLeft = GameConfig.birdX - GameConfig.birdSize / 2 + 0.02;
    final birdRight = GameConfig.birdX + GameConfig.birdSize / 2 - 0.02;
    final birdTop = _birdY - GameConfig.birdSize / 2 + 0.02;
    final birdBottom = _birdY + GameConfig.birdSize / 2 - 0.02;

    for (var pipe in _pipes) {
      final pipeLeft = pipe.x - GameConfig.pipeWidth / 2;
      final pipeRight = pipe.x + GameConfig.pipeWidth / 2;

      if (birdRight > pipeLeft && birdLeft < pipeRight) {
        final gapTop = pipe.topHeight * 2 - 1;
        final gapBottom = gapTop + _level.pipeGap;

        if (birdTop < gapTop || birdBottom > gapBottom) {
          return true;
        }
      }
    }
    return false;
  }

  void _checkLevelUp() {
    int newLevel = 0;
    for (int i = GameConfig.levels.length - 1; i >= 0; i--) {
      if (_score >= GameConfig.levels[i].scoreToUnlock) {
        newLevel = i;
        break;
      }
    }
    if (newLevel > _currentLevel) {
      _currentLevel = newLevel;
      _gameState = GameState.levelUp;
      _audio.playLevelUp();
      _levelUpController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _gameState = GameState.playing);
        }
      });
    }
  }

  void _triggerDeath() {
    _gameState = GameState.dead;
    _gameLoopController.stop();
    _audio.playDie();
    _deathAnimController.forward(from: 0);
    _saveHighScore();
  }

  void _flap() {
    if (_gameState == GameState.dead || _gameState == GameState.paused) return;
    if (_gameState == GameState.levelUp) return;

    if (_gameState == GameState.idle) {
      _currentLevel = _selectedStartLevel;
      _gameState = GameState.playing;
      _gameLoopController.forward();
    }

    _birdVelocity = -0.055;
    _audio.playFlap();
  }

  void _restart() {
    setState(() {
      _birdY = 0.0;
      _birdVelocity = 0.0;
      _birdRotation = 0.0;
      _score = 0;
      _currentLevel = _selectedStartLevel;
      _pipes.clear();
      _bonusStars.clear();
      _pipeTimer = 0;
      _gameState = GameState.idle;
      _hasUsedRevive = false;
    });
    _deathAnimController.reset();
  }

  void _revive() {
    if (_coins < GameConfig.reviveCost || _hasUsedRevive) return;

    setState(() {
      _coins -= GameConfig.reviveCost;
      _hasUsedRevive = true;

      // Reset bird to safe state at current position
      _birdVelocity = 0.0;
      _birdRotation = 0.0;
      // Clamp bird Y to safe zone
      _birdY = _birdY.clamp(-0.8, 0.7);

      // Remove pipes that are close to bird to prevent instant re-crash
      _pipes.removeWhere((p) {
        final dist = (p.x - GameConfig.birdX).abs();
        return dist < 0.3;
      });
      _bonusStars.removeWhere((s) {
        final dist = (s.x - GameConfig.birdX).abs();
        return dist < 0.3;
      });

      _gameState = GameState.playing;
    });

    _deathAnimController.reset();
    _gameLoopController.forward();
    _saveCoins();
  }

  void _togglePause() {
    if (_gameState == GameState.playing) {
      setState(() => _gameState = GameState.paused);
      _gameLoopController.stop();
      return;
    }

    if (_gameState == GameState.paused) {
      setState(() => _gameState = GameState.playing);
      _gameLoopController.forward();
    }
  }

  void _openOptions() {
    _stateBeforeOptions = _gameState;
    if (_gameState == GameState.playing) {
      _togglePause();
    }
    setState(() {});
    _showOptionsSheet();
  }

  void _openCoinShop() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoinShopScreen(
          currentCoins: _coins,
        ),
      ),
    ).then((_) {
      // Refresh coins after returning from shop
      _loadHighScore();
    });
  }

  void _closeOptions() {
    Navigator.of(context).pop();
    if (_stateBeforeOptions == GameState.playing && mounted) {
      _togglePause();
    }
  }

  void _setStartLevel(int level) {
    setState(() {
      _selectedStartLevel = level;
      if (_gameState == GameState.idle) {
        _currentLevel = level;
      }
    });
    _saveStartLevel(level);
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    _deathAnimController.dispose();
    _levelUpController.dispose();
    _idlePulseController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPlaying =
        _gameState == GameState.playing || _gameState == GameState.levelUp;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _flap(),
        child: Stack(
          children: [
            // Background
            BackgroundWidget(
              groundOffset: _groundOffset,
              isPlaying: isPlaying,
            ),

            // Pipes
            ..._pipes.map((pipe) => PipeWidget(
                  pipe: pipe,
                  pipeGap: _level.pipeGap,
                  screenSize: size,
                )),

            // Bonus stars
            ..._bonusStars.map((star) => _BonusStarWidget(
                  star: star,
                  screenSize: size,
                )),

            // Bird (hide during idle — logo is shown instead)
            if (_gameState != GameState.idle)
              BirdWidget(
                birdY: _birdY,
                rotation: _birdRotation,
                isDead: _gameState == GameState.dead,
                deathAnimation: _deathAnimController,
              ),

            // Score
            if (_gameState != GameState.idle)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '$_score',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(
                          _currentLevel,
                        ).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        GameConfig.levels[_currentLevel].name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    // Coin HUD (only during play, not on death)
                    if (_gameState != GameState.dead)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                '$_coins',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Sound toggle
            Positioned(
              top: 52,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _audio.soundEnabled = !_audio.soundEnabled;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _audio.soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Pause button
            if (_gameState == GameState.playing ||
                _gameState == GameState.paused)
              Positioned(
                top: 52,
                left: 16,
                child: _buildIconAction(
                  icon: _gameState == GameState.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onTap: _togglePause,
                ),
              ),

            // Options button
            Positioned(
              top: 52,
              right: 64,
              child: _buildIconAction(
                icon: Icons.settings_rounded,
                onTap: _openOptions,
              ),
            ),

            // Idle screen
            if (_gameState == GameState.idle) _buildIdleScreen(),

            // Death screen
            if (_gameState == GameState.dead) _buildDeathScreen(),

            if (_gameState == GameState.paused) _buildPausedOverlay(),

            // Level up overlay
            if (_gameState == GameState.levelUp) _buildLevelUpOverlay(),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF4CAF50);
      case 1:
        return const Color(0xFFFF9800);
      case 2:
        return const Color(0xFFF44336);
      default:
        return Colors.blue;
    }
  }

  Widget _buildIdleScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game logo with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'assets/images/logo/app_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFFFD54F)],
              ).createShader(bounds),
              child: const Text(
                'FLAP & FLY',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats row — Best Score & Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Best score
                  Column(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: Colors.amber.withValues(alpha: 0.9), size: 22),
                      const SizedBox(height: 4),
                      Text(
                        '$_highScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'BEST',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  // Coins
                  Column(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'COINS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Animated TAP TO START button
            AnimatedBuilder(
              animation: _idlePulseAnim,
              builder: (context, child) => Transform.scale(
                scale: _idlePulseAnim.value,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD600), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'TAP TO START',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options button
            GestureDetector(
              onTap: _openOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_rounded, color: Colors.white60, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'OPTIONS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Level cards
            _buildLevelInfo(),

            const SizedBox(height: 16),

            // Coin Shop button
            GestureDetector(
              onTap: _openCoinShop,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.orange.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🛒', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'COIN SHOP',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeathScreen() {
    final canRevive = _coins >= GameConfig.reviveCost && !_hasUsedRevive;

    return AnimatedBuilder(
      animation: _deathAnimController,
      builder: (context, _) {
        return Center(
          child: FadeTransition(
            opacity: _deathAnimController,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '💀  GAME OVER',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreCard('SCORE', '$_score', Colors.amber),
                      _buildScoreCard('BEST', '$_highScore', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Coin balance display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '$_coins coins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Revive / Continue button
                  if (canRevive)
                    GestureDetector(
                      onTap: _revive,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00E676),
                              Color(0xFF00C853),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪙',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'CONTINUE  (${GameConfig.reviveCost} coins)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _restart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD600), Color(0xFFFF6F00)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Text(
                        'PLAY AGAIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSmallActionButton(
                    icon: Icons.settings_rounded,
                    label: 'OPTIONS',
                    onTap: _openOptions,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openCoinShop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🛒', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'GET COINS',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelUpOverlay() {
    return Center(
      child: ScaleTransition(
        scale: _levelUpAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getLevelColor(_currentLevel).withValues(alpha: 0.9),
                _getLevelColor(_currentLevel).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _getLevelColor(_currentLevel).withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              const Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                GameConfig.levels[_currentLevel].name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 44),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                color: Colors.white, size: 46),
            const SizedBox(height: 8),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _buildSmallActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'RESUME',
              onTap: _togglePause,
            ),
            const SizedBox(height: 10),
            _buildSmallActionButton(
              icon: Icons.settings_rounded,
              label: 'OPTIONS',
              onTap: _openOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 36, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF102033),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_rounded,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'OPTIONS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _closeOptions,
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildOptionRow(
                        icon: _audio.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: 'Sound',
                        trailing: Switch(
                          value: _audio.soundEnabled,
                          activeThumbColor: Colors.amber,
                          onChanged: (value) {
                            setState(() => _audio.soundEnabled = value);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'START LEVEL',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            List.generate(GameConfig.levels.length, (index) {
                          final level = GameConfig.levels[index];
                          final selected = _selectedStartLevel == index;
                          return ChoiceChip(
                            label: Text(level.name),
                            selected: selected,
                            selectedColor: _getLevelColor(index),
                            backgroundColor: Colors.white12,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) {
                              _setStartLevel(index);
                              setSheetState(() {});
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      _buildOptionRow(
                        icon: Icons.emoji_events_rounded,
                        label: 'Best score',
                        trailing: Text(
                          '$_highScore',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOptionRow(
                        icon: Icons.monetization_on_rounded,
                        label: 'Coins',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _resetHighScore();
                          setSheetState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('RESET BEST SCORE'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _closeOptions,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'DONE',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: GameConfig.levels.asMap().entries.map((entry) {
        final index = entry.key;
        final l = entry.value;
        final unlocked = _highScore >= l.scoreToUnlock;
        final isSelected = _selectedStartLevel == index;
        final levelColor = _getLevelColor(index);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? levelColor.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? levelColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: unlocked ? levelColor : Colors.white24,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                l.name,
                style: TextStyle(
                  color: unlocked ? Colors.white70 : Colors.white30,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              if (l.scoreToUnlock > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${l.scoreToUnlock}+',
                    style: TextStyle(
                      color: unlocked
                          ? Colors.white30
                          : Colors.white.withValues(alpha: 0.15),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BonusStar {
  static const double size = 0.075;

  double x;
  double y;
  bool collected = false;

  _BonusStar({
    required this.x,
    required this.y,
  });
}

class _BonusStarWidget extends StatelessWidget {
  final _BonusStar star;
  final Size screenSize;

  const _BonusStarWidget({
    required this.star,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final starSize = _BonusStar.size * screenSize.width;
    final starX = (star.x + 1) / 2 * screenSize.width;
    final starY = (star.y + 1) / 2 * screenSize.height;

    return Positioned(
      left: starX - starSize / 2,
      top: starY - starSize / 2,
      width: starSize,
      height: starSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.7),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Color(0xFFFF6F00),
          size: 24,
        ),
      ),
    );
  }
}

class _BirdEmoji extends StatefulWidget {
  const _BirdEmoji();

  @override
  State<_BirdEmoji> createState() => _BirdEmojiState();
}

class _BirdEmojiState extends State<_BirdEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: const Text('🐦', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}
