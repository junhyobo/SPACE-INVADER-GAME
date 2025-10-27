import 'dart:ui';
import '../core/entity.dart';

class TimedGifFx extends Entity {
  final String asset;
  double ttl;
  final bool onTop;

  TimedGifFx({
    required this.asset,
    required super.position,  
    this.ttl = 0.30,
    this.onTop = false,
    super.size = const Size(250, 250), 
  }) : super(
          id: nextId('fx'), 
          velocity: Offset.zero,
        );

  @override
  void update(double dt) {
    ttl -= dt;
    if (ttl <= 0) dead = true;
  }
}