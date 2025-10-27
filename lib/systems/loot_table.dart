import 'dart:math';
import 'dart:ui';
import '../items/powerup.dart';
import '../items/heal_powerup.dart';
import '../items/ammo_powerup.dart';
import '../items/shield_powerup.dart';
import '../util/game_tuning.dart';

class LootTable {
  final Random _rng = Random();

  PowerUp? roll({required Offset at, required bool isAsteroid}) {
    final s = GameTuning.dropScale;
    final alienChance = (GameTuning.dropHealAlien + GameTuning.dropAmmoAlien) * s;
    final astChance   = (GameTuning.dropHealAst   + GameTuning.dropAmmoAst)   * s;
    final dropChance = isAsteroid ? astChance : alienChance;

    final r = _rng.nextDouble();
    if (r >= dropChance) return null;

    // 1/3 mỗi loại khi đã rơi
    switch (_rng.nextInt(3)) {
      case 0: return HealPowerUp(pos: at);
      case 1: return AmmoPowerUp(pos: at);
      default: return ShieldPowerUp(pos: at);
    }
  }
}
