
import 'powerup.dart';
import '../actors/player.dart';
import '../enums.dart';

class AmmoPowerUp extends PowerUp {
  AmmoPowerUp({required super.pos})  
      : super(type: PowerUpType.ammo);

  @override
  void applyTo(Player p) {
    p.upgradeBulletLevel();
  }
}