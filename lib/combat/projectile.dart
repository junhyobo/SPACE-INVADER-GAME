import 'dart:ui';
import '../core/entity.dart';
import '../util/game_tuning.dart';

class Bullet extends Entity {
  final int dmg;
  // 0 = player, 1 = enemy
  final int ownerTeam;
  final String asset;

  Bullet({
    required super.position,
    required this.dmg,
    required this.ownerTeam,
    required this.asset,
    required Offset speed,
    required super.size,
  }) : super(
    velocity: speed,
    hitboxScale: 0.4,
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (position.dy < GameTuning.screenTopLimit || position.dy > GameTuning.screenBottomLimit) {
      dead = true;
    }
  }
}