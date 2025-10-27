import 'dart:ui';
import 'interfaces.dart';

int _uid = 0;
String nextId(String p) => '${p}_${_uid++}';

abstract class Entity implements IUpdatable, ICollidable {
  final String id;
  Offset position;
  Size size;
  Offset velocity;
  bool dead;
  double hitboxScale;

  Entity({
    String? id,
    required this.position,
    required this.size,
    this.velocity = Offset.zero,
    this.dead = false,
    
    this.hitboxScale = 1.0,
  }) : id = id ?? nextId('e');

   @override
  Rect get hitBox => Rect.fromCenter(
    center: position,
    width: size.width * hitboxScale,
    height: size.height * hitboxScale,
  );
  @override
  void update(double dt) { position += velocity * dt; }

}
