
import 'powerup.dart';
import '../actors/player.dart';
import '../enums.dart';
class ShieldPowerUp extends PowerUp {
 ShieldPowerUp({required super.pos})  
      : super(type: PowerUpType.shield);
  @override
  void applyTo(Player p) {
    p.addShield(1);
  }
}
