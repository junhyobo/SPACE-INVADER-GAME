import 'package:flutter/material.dart';
import '../../util/game_tuning.dart';
import '../../actors/player.dart';
import '../../services/sfx_service.dart';
typedef ToastFn = void Function(String text, Color color);
typedef SfxFn = Future<void> Function();

class ComboSystem {
  int _combo = 0;
  double _comboTimer = 0;
  int _lastAmmoTierAwarded = 0;
  int _lastScoreBlockAwarded = 0;
  
  final SfxService sfxService;

  ComboSystem(this.sfxService);

  void update(double dt, void Function(String, {Color ? color}) addToast) { 
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        resetCombo();
      }
    }
  }

  void addKill(Player player, void Function(String, {Color ? color}) addToast) { 
    if (_comboTimer <= 0) {
      _combo = 0;
      _lastAmmoTierAwarded = 0;
      _lastScoreBlockAwarded = 0;
    }
    
    _combo += 1;
    _comboTimer = GameTuning.comboTimeout;

    final tiers = _combo ~/ GameTuning.ammoTierStep;
    if (tiers > _lastAmmoTierAwarded) {
      for (int j = _lastAmmoTierAwarded + 1; j <= tiers; j++) {
        final awardAmmo = j * GameTuning.ammoTierScale;
        final gained = player.addAmmo(awardAmmo);
        if (gained > 0) {
          addToast('Combo x$_combo  +$gained ammo',
              color: const Color(0xFF4DD0E1));
          sfxService.Combo(combo);
        } else {
          addToast('Ammo FULL', color: const Color(0xFFFFAB40));
        }
      }
      _lastAmmoTierAwarded = tiers;
    }

    final blocks = _combo ~/ GameTuning.scoreBlockStep;
    if (blocks > _lastScoreBlockAwarded) {
      for (int k = _lastScoreBlockAwarded + 1; k <= blocks; k++) {
        final bonus = k * GameTuning.scoreBlockScale;
        addToast('Combo x$_combo  +$bonus SCORE',
            color: const Color(0xFFFFFF8D));
        sfxService.Combo(combo);
      }
      _lastScoreBlockAwarded = blocks;
    }
  }

  void resetCombo() { 
    _combo = 0;
    _comboTimer = 0;
    _lastAmmoTierAwarded = 0;
    _lastScoreBlockAwarded = 0;
  }

  int get combo => _combo;
  double get comboTimeLeft => _comboTimer;
}