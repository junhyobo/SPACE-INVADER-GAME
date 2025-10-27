import 'dart:ui';
import '../core/entity.dart';
import '../util/game_tuning.dart';
import '../actors/player.dart';
import '../enums.dart';

abstract class PowerUp extends Entity {
  final PowerUpType type;

  PowerUp({
    required this.type,
    required Offset pos,
  }) : super(
          id: nextId('pu'),  
          position: pos,
          size: GameTuning.powerUpSize,
          velocity: const Offset(0, GameTuning.powerUpFallSpeed),
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (position.dy > 1600) dead = true;

  }

  void applyTo(Player p);
}
