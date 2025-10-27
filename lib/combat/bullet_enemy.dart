import 'dart:ui';
import '../assets.dart';
import '../util/game_tuning.dart';
import 'projectile.dart';

/// Đạn QUÁI
class EnemyBullet extends Bullet {
  EnemyBullet({
    required super.position,
    super.dmg = 10,
  }) : super(
          ownerTeam: 1,
          asset: Assets.bulletEnemy,
          speed: Offset(0, GameTuning.v(GameTuning.bulletSpeedEnemy)),
          size: GameTuning.sz(GameTuning.bulletEnemySize),
        );
}
