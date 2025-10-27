import 'dart:ui';
import '../../combat/projectile.dart';
import '../../actors/player.dart';
import '../../actors/enemy.dart';
import '../../actors/asteroid.dart';
import '../../items/powerup.dart';
import '../../services/sfx_service.dart';
import '../../effects/timed_gif_fx.dart';
import '../../assets.dart';
import '../../util/game_tuning.dart';
import '../../enums.dart';
import '../../core/entity.dart';

class CollisionSystem {
  final SfxService sfxService;

  CollisionSystem(this.sfxService);

  // Static collision methods
  static bool bulletHitsEnemy(Bullet b, Enemy e) {
    if (b.ownerTeam != 0) return false;
    return e.hitBox.overlaps(b.hitBox);
  }

  static bool bulletHitsPlayer(Bullet b, Player p) {
    if (b.ownerTeam != 1) return false;
    final rect = Rect.fromCircle(center: p.position, radius: 18);
    return rect.overlaps(b.hitBox);
  }

  static bool playerHitsEnemy(Player p, Enemy e) {
    final playerRect = Rect.fromCircle(center: p.position, radius: 15);
    return playerRect.overlaps(e.hitBox);
  }

  static bool playerGetsPowerUp(Player p, Offset powerUpPos, {double radius = 20}) {
    return (p.position - powerUpPos).distance <= radius;
  }

  // Instance methods
  void checkAllCollisions({
    required List<Bullet> bullets,
    required List<Enemy> enemies,
    required Player player,
    required List<PowerUp> powerups,
    required Function(Entity) spawn,
    required Function(Entity) kill,
    required Function(int) addScore,
    required Function(Offset, bool) dropLoot,
    required void Function(String, Color) addToast,
    required Function() checkGameOver,
    required void Function() onPlayerKill, // dùng void Function() để khỏi import
  }) {
    _checkPlayerBulletCollisions(
      bullets,
      enemies,
      spawn,
      kill,
      addScore,
      dropLoot,
      addToast,
      (_) => onPlayerKill(), // <-- GỌI combo khi enemy chết bởi đạn
    );

    _checkEnemyBulletCollisions(bullets, player, spawn, kill, checkGameOver);

    _checkPlayerEnemyCollisions(
      player,
      enemies,
      spawn,
      kill,
      checkGameOver,
      onPlayerKill, // <-- truyền tiếp để gọi khi húc chết enemy
    );

    _checkPowerUpCollisions(powerups, player, spawn, kill, addScore);
  }

  void _checkPlayerBulletCollisions(
    List<Bullet> bullets,
    List<Enemy> enemies,
    Function(Entity) spawn,
    Function(Entity) kill,
    Function(int) addScore,
    Function(Offset, bool) dropLoot,
    void Function(String, Color) addToast,
    void Function(Enemy en)? onEnemyKilled,
  ) {
    for (final b in List<Bullet>.from(bullets)) {
      if (b.ownerTeam != 0) continue;
      for (final en in List<Enemy>.from(enemies)) {
        if (!b.dead && !en.dead && bulletHitsEnemy(b, en)) {
          b.dead = true;
          en.takeDamage(b.dmg);

          if (en.isDead) {
            addScore(500);
            dropLoot(en.position, en is Asteroid);

            spawn(TimedGifFx(
              asset: Assets.fxHitGif,
              position: en.position,
              ttl: 0.10,
              size: GameTuning.fxHitSize,
            ));
            sfxService.playExplosion();

            onEnemyKilled?.call(en); // <-- báo kill (combo)
            kill(en);
          }
          break;
        }
      }
      if (b.dead) kill(b);
    }
  }

  void _checkEnemyBulletCollisions(
    List<Bullet> bullets,
    Player player,
    Function(Entity) spawn,
    Function(Entity) kill,
    Function() checkGameOver,
  ) {
    for (final b in List<Bullet>.from(bullets)) {
      if (b.ownerTeam != 1) continue;
      if (!b.dead && bulletHitsPlayer(b, player)) {
        b.dead = true;
        if (player.shield > 0) {
          spawn(TimedGifFx(
            asset: Assets.fxShieldBreakGif,
            position: player.position,
            ttl: 0.30,
            size: GameTuning.fxShieldBreakSize,
            onTop: true,
          ));
          player.shield -= 1;
          sfxService.playShieldBreak();
        } else {
          spawn(TimedGifFx(
            asset: Assets.fxHitGif,
            position: b.position,
            ttl: 0.10,
            size: GameTuning.fxHitSize,
          ));
          sfxService.playExplosion();
          player.takeDamage(10);
          if (player.isDead) checkGameOver();
        }
      }
      if (b.dead) kill(b);
    }
  }

  void _checkPlayerEnemyCollisions(
    Player player,
    List<Enemy> enemies,
    Function(Entity) spawn,
    Function(Entity) kill,
    Function() checkGameOver,
    void Function() onPlayerKill, 
  ) {
    for (final en in List<Enemy>.from(enemies)) {
      if (!en.dead && playerHitsEnemy(player, en)) {
        final hitPos = Offset(
          (player.position.dx + en.position.dx) / 2,
          (player.position.dy + en.position.dy) / 2,
        );
         spawn(TimedGifFx(
        asset: Assets.fxHitGif,
        position: hitPos,
        ttl: 0.10,
        size: GameTuning.fxHitSize,
      ));
        if (player.shield > 0) {
          spawn(TimedGifFx(
            asset: Assets.fxShieldBreakGif,
            position: player.position,
            ttl: 0.15,
            size: GameTuning.fxShieldBreakSize,
            onTop: true,
          ));
          player.shield -= 1;
          sfxService.playShieldBreak();
          } 
          else {
          sfxService.playExplosion();
          player.takeDamage(GameTuning.playerCollisionDamage);
          if (player.isDead) checkGameOver();
        }
        en.takeDamage(en.hp);
        if (en.dead) kill(en);
        break;
      }
      
    }
  }

  void _checkPowerUpCollisions(
    List<PowerUp> powerups,
    Player player,
    Function(Entity) spawn,
    Function(Entity) kill,
    Function(int) addScore,
  ) {
    for (final pu in List<PowerUp>.from(powerups)) {
      if (playerGetsPowerUp(player, pu.position)) {
        _handlePowerUpPickup(pu, player, spawn);
        addScore(100);
        sfxService.playPickup();
        kill(pu);
      }
    }
  }

  void _handlePowerUpPickup(PowerUp pu, Player player, Function(Entity) spawn) {
    String asset;
    switch (pu.type) {
      case PowerUpType.heal:
        asset = Assets.fxPickupHealPng;
        break;
      case PowerUpType.ammo:
        asset = Assets.fxPickupAmmoPng;
        break;
      case PowerUpType.shield:
        asset = Assets.fxPickupShieldPng;
        break;
    }

    spawn(TimedGifFx(
      asset: asset,
      position: player.position,
      ttl: 0.3,
      size: GameTuning.fxPickupSize,
      onTop: true,
    ));

    pu.applyTo(player);
  }
}
