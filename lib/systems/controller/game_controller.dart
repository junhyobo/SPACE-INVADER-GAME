import 'dart:math';
import 'dart:ui';

import '../../core/entity.dart';
import '../../actors/player.dart';
import '../../actors/enemy.dart';
import '../../actors/asteroid.dart';
import '../../combat/projectile.dart';
import '../../combat/bullet_enemy.dart';
import '../../items/powerup.dart';
import '../../effects/timed_gif_fx.dart';
import '../../util/game_tuning.dart';
import '../../services/sfx_service.dart';
import '../../enums.dart';
import '../level_manager.dart';
import '../loot_table.dart';
import '../score_manager.dart';
import '../mechanics/collision_system.dart';
import '../mechanics/combo_system.dart';
import '../warning_system.dart';
import '../input/input_system.dart';
import '../ui_toast.dart';
import '../../models/high_score.dart';

class Score { int value = 0; }

class GameController {
  final List<TimedGifFx> gifFxs = [];
  final List<UiToast> uiToasts = [];
  final Player player;
  final String playerName;
  final InputSystem input = InputSystem();

  GameStage stage = GameStage.playing;
  String currentShipAsset;
  Size playArea = const Size(400, 700);

  final List<Entity> entities = [];
  final List<Enemy> enemies = [];
  final List<Bullet> bullets = [];
  final List<PowerUp> powerups = [];
  final List<Entity> _toAdd = [];
  final List<Entity> _toRemove = [];

  final _rng = Random();
  final LevelManager levels = LevelManager();
  final LootTable loot = LootTable();
  final ScoreManager _scoreManager = ScoreManager();
  late final CollisionSystem collisionSystem;
  late final ComboSystem comboSystem;
  late final WarningSystem warningSystem;

  final Score score = Score();
  bool _layoutInitialized = false;
  double _time = 0;
  double _nextEnemyShotTime = 0;

  GameController(
    this.player, {
    required this.currentShipAsset,
    required this.playerName,
  }) {
    collisionSystem = CollisionSystem(SfxService.I);
    comboSystem = ComboSystem(SfxService.I);
    warningSystem = WarningSystem(SfxService.I);
  }

  int get combo => comboSystem.combo;
  double get comboTimer => comboSystem.comboTimeLeft;

  void setPlayArea(Size size) {
    playArea = size;

    levels
      ..setSpawnBaseY(-40)
      ..setScreenHeight(size.height)
      ..setScreenWidth(playArea.width)
      ..setSpawnCenterX(playArea.width * 0.5)
      ..rebuildForCurrentStage();

    if (!_layoutInitialized) {
      player.position = Offset(playArea.width * 0.5, playArea.height * 0.8);
      input.target = player.position; // dùng API chung
      _layoutInitialized = true;
    }
  }

  void startGame() {
    entities.clear(); enemies.clear(); bullets.clear(); powerups.clear();
    _toAdd.clear(); _toRemove.clear();
    gifFxs.clear(); uiToasts.clear(); score.value = 0;

    player.resetToBaseStats();
    entities.add(player);

    if (playArea.width > 0 && playArea.height > 0) {
      player.position = Offset(playArea.width * 0.5, playArea.height * 0.8);
    }
    input.target = player.position; // API chung

    levels.reset();
    levels.rebuildForCurrentStage();
    stage = GameStage.playing;
    comboSystem.resetCombo();
    warningSystem.reset();

    _time = 0;
    _nextEnemyShotTime = 0;
  }

void spawn(Entity e) {
  // Chỉ ép về mép trên với QUÁI thường, KHÔNG áp dụng cho thiên thạch
  if (e is Enemy && e is! Asteroid) {
    final double offTop = min(GameTuning.screenTopLimit, -e.size.height * 0.8);
    if (e.position.dy >= 0) {
      e.position = Offset(e.position.dx, offTop);
    }
  }

  // Asteroid: giữ nguyên vị trí mà LevelManager đã chọn (mép trái + phần trên)
  _toAdd.add(e);
}

  void kill(Entity e) => _toRemove.add(e);

  void _applyQueuedChanges() {
    if (_toRemove.isNotEmpty) {
      entities.removeWhere(_toRemove.contains);
      enemies.removeWhere(_toRemove.contains);
      bullets.removeWhere(_toRemove.contains);
      powerups.removeWhere(_toRemove.contains);
      gifFxs.removeWhere(_toRemove.contains);
      _toRemove.clear();
    }
    if (_toAdd.isNotEmpty) {
      for (final e in _toAdd) {
        entities.add(e);
        if (e is Enemy) enemies.add(e);
        if (e is Bullet) bullets.add(e);
        if (e is PowerUp) powerups.add(e);
        if (e is TimedGifFx) gifFxs.add(e);
      }
      _toAdd.clear();
    }
  }

  bool _isEnemyCleared(Enemy e) {
    const sidePad = 120.0;
    const bottomPad = 40.0;
    final outBottom = e.position.dy > playArea.height + bottomPad;
    final outSide = e.position.dx < -sidePad || e.position.dx > playArea.width + sidePad;
    return e.dead || outBottom || outSide;
  }

  bool _isWaveClearedSafe() {
    if (_toAdd.any((e) => e is Enemy)) return false;
    return enemies.every(_isEnemyCleared);
  }

  void _saveScore() {
    final newHighScore = HighScore(
      score: score.value,
      date: _currentDateString(),
      playerName: playerName,
      avatar: currentShipAsset,
    );
    _scoreManager.addScore(newHighScore);
  }

  String _currentDateString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  void _checkGameOver() {
    if (player.isDead || player.currentAmmo <= 0) {
      stage = GameStage.gameOver;
      _saveScore();
    }
  }

  void update(double dt) {
    if (stage != GameStage.playing) return;

    _time += dt;

    comboSystem.update(
      dt,
      (String text, {Color? color}) => uiToasts.add(UiToast(text, color ?? const Color(0xFFB3E5FC))),
    );
    warningSystem.checkWarnings(player);

    // 1) Di chuyển tức thời theo target chung
    _updatePlayerPositionInstant(dt);

    // 2) Hết đạn?
    if (player.currentAmmo <= 0) {
      _checkGameOver();
      if (stage != GameStage.playing) return;
    }

    // 3) Bắn
    _updateShooting();

    // 4) Update entities
    _updateEntities(dt);

    // 5) Enemy bắn ngẫu nhiên
    _enemyRandomFire();

    // 6) Va chạm
    _handleCollisions();

    // 7) Áp hàng đợi
    _applyQueuedChanges();

    // 8) Level
    levels.update(dt, (enemy) => spawn(enemy), _isWaveClearedSafe);

    // 9) Áp lần cuối
    _applyQueuedChanges();

    // 10) Toast TTL
    _updateToasts(dt);
  }

  /// Tên hàm chung, thay _updatePlayerMovement trước đây
  void _updatePlayerPositionInstant(double dt) {
    final double pad = GameTuning.playerPad;
    final Offset target = Offset(
      input.target.dx.clamp(pad, playArea.width - pad),
      input.target.dy.clamp(pad, playArea.height - pad),
    );

    if (input.moveActive) {
      player.position = target; // tức thời
    }

    player.update(dt);
  }

  /// Tên hàm chung, thay _handlePlayerShooting
  void _updateShooting() {
    if (input.fireActive && player.canShoot()) {
      SfxService.I.playShoot();
      player.shoot(spawn);
    }
  }

  void _updateEntities(double dt) {
    for (final e in List<Entity>.from(entities)) {
      e.update(dt);
      if (e.dead) kill(e);
    }
  }

  void _enemyRandomFire() {
    if (_time < _nextEnemyShotTime || enemies.isEmpty) return;

    final shooters = enemies.where((e) => !e.dead && e is! Asteroid).toList();
    if (shooters.isNotEmpty) {
      final en = shooters[_rng.nextInt(shooters.length)];
      spawn(EnemyBullet(
        position: en.position + Offset(0, en.size.height * 0.55),
        dmg: 10,
      ));
    }

    _nextEnemyShotTime = _time + 0.3;
  }

  void _handleCollisions() {
    collisionSystem.checkAllCollisions(
      bullets: bullets,
      enemies: enemies,
      player: player,
      powerups: powerups,
      spawn: spawn,
      kill: kill,
      addScore: (points) => score.value += points,
      dropLoot: (position, isAsteroid) {
        final drop = loot.roll(at: position, isAsteroid: isAsteroid);
        if (drop != null) spawn(drop);
      },
      addToast: (String text, Color color) => uiToasts.add(UiToast(text, color)),
      checkGameOver: _checkGameOver,
      onPlayerKill: () {
        comboSystem.addKill(
          player,
          (text, {color}) => uiToasts.add(UiToast(text, color ?? const Color(0xFFB3E5FC))),
        );
      },
    );
  }

  void _updateToasts(double dt) {
    for (final t in uiToasts) {
      t.ttl -= dt;
    }
    uiToasts.removeWhere((t) => t.ttl <= 0);
  }
}
