import 'dart:ui';
import '../assets.dart';
import '../util/game_tuning.dart';
import 'projectile.dart';

/// Đạn NGƯỜI CHƠI
class PlayerBullet extends Bullet {
  PlayerBullet({
    required super.position,
    super.dmg = 10,
  }) : super(
          ownerTeam: 0,
          asset: Assets.bulletPlayer,
          speed: Offset(0, GameTuning.v(GameTuning.bulletSpeedPlayer)),
          size: GameTuning.sz(GameTuning.bulletPlayerSize),
        );
}
