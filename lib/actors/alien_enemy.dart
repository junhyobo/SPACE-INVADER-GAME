import 'dart:ui';
import 'dart:math' as math;
import '../util/game_tuning.dart';
import 'enemy.dart';

class AlienEnemy extends Enemy {
  double t = 0;
  double amp = 60;
  double freq = 2.0;

  AlienEnemy({required super.position,}) {
    speed = GameTuning.alienSpeedY;
    final baseHp = GameTuning.lvlAlienBaseHp;
      maxHp = baseHp;
      hp    = baseHp;
    size = GameTuning.sz(GameTuning.alienSize);
  }

  @override
  void update(double dt) {
    t += dt;
    final next = fireCooldown - dt;
    fireCooldown = next > 0 ? next : 0;
    velocity = Offset(math.sin(t * freq) * amp, speed);

    super.update(dt);
    if (position.dy > GameTuning.screenBottomLimit) dead = true;
  }
}
