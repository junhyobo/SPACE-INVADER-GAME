
import 'powerup.dart';
import '../actors/player.dart';
import '../enums.dart';

class HealPowerUp extends PowerUp {
  HealPowerUp({required super.pos})  
      : super(type: PowerUpType.heal);

  @override
  void applyTo(Player p) {
    final healAmount = (p.maxHp / 4).round();
    p.hp = (p.hp + healAmount).clamp(0, p.maxHp);
  }
}