import 'dart:ui';
import '../core/entity.dart';
import '../core/interfaces.dart';

class Enemy extends Entity implements IDamageable {

  double fireCooldown = 0;
  @override int maxHp = 30;
  @override int hp = 30;
  double speed = 100;

  Enemy({required super.position,})
      : super(id: nextId('en'),
       size: const Size(100, 100),
       hitboxScale: 0.3,);

  @override
  void update(double dt) {
    if (velocity.dx == 0 && velocity.dy == 0) {
      velocity = Offset(0, speed);
    }
    super.update(dt);
  }

  @override
  void takeDamage(int dmg) {
    hp = (hp - dmg).clamp(0, maxHp);
    if (hp == 0) dead = true;
  }

  @override
  bool get isDead => dead;
}
