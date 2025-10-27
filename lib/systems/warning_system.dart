import '../actors/player.dart';
import '../services/sfx_service.dart';
import '../util/game_tuning.dart';

class WarningSystem {
  bool _warnedHp = false;
  bool _warnedAmmo = false;
  final SfxService sfxService;

  WarningSystem(this.sfxService);

  void checkWarnings(Player player) {
    final hpRatio = player.hp / player.maxHp;
    final ammoRatio = player.ammoLimit == 0 ? 0.0 : (player.currentAmmo / player.ammoLimit);

    // HP Warning
    if (hpRatio < GameTuning.lowResourceThreshold && !_warnedHp) {
      sfxService.playWarningSound();
      _warnedHp = true;
    } else if (hpRatio > GameTuning.lowResourceThreshold + 0.1) {
      _warnedHp = false;
    }

    // Ammo Warning
    if (ammoRatio < GameTuning.lowResourceThreshold && !_warnedAmmo) {
      sfxService.playWarningSound();
      _warnedAmmo = true;
    } else if (ammoRatio > GameTuning.lowResourceThreshold + 0.1) {
      _warnedAmmo = false;
    }
  }

  void reset() {
    _warnedHp = false;
    _warnedAmmo = false;
  }
}