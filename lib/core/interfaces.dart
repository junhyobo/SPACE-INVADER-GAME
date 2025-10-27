import 'dart:ui';
import 'entity.dart';
abstract class IUpdatable { void update(double dt); }
abstract class ICollidable { Rect get hitBox; }

abstract class IDamageable {
  int get hp;
  int get maxHp;
  void takeDamage(int dmg);
  bool get isDead;
}
abstract class IShootable {
  void shoot(void Function(Entity e) spawn);

}
