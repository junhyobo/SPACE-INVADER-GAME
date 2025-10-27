import 'dart:ui';
import '../util/game_tuning.dart';
import 'enemy.dart';

class Asteroid extends Enemy {
  final double dirX;
  Asteroid({required super.position,required this.dirX}) {
    speed = GameTuning.asteroidSpeedY;
    final baseHp   = GameTuning.lvlAlienBaseHp;
      final meteorHp = (baseHp * GameTuning.lvlMeteorHpMult).round();
      maxHp = meteorHp;
      hp    = meteorHp;
    size = GameTuning.sz(GameTuning.asteroidSize);
  }

  @override
  void update(double dt) {
    velocity = Offset(dirX, speed);
    super.update(dt);
    if (position.dy > GameTuning.screenBottomLimit ||
       position.dx < GameTuning.screenLeftLimit ||        
        position.dx > GameTuning.screenSideLimit) {
      dead = true;
    }
  }
}
