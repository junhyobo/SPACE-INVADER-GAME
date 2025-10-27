import 'dart:ui' show Offset, Size;
import 'package:flutter/material.dart';

import '../../systems/controller/game_controller.dart';
import '../../assets.dart';
import '../../actors/asteroid.dart';
import '../../actors/enemy.dart';
import '../../combat/projectile.dart';
import '../../items/powerup.dart';
import '../../effects/timed_gif_fx.dart';


class GameSprites extends StatelessWidget {
  final GameController controller;

  const GameSprites({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Enemies
        ...controller.enemies.map(_buildEnemySprite),

        // Enemy HP Bars (đã lọc Asteroid)
        ...controller.enemies
 /*  */           .where((en) => en is! Asteroid)
            .map(_buildEnemyHpBar),

        // Bullets
        ...controller.bullets.map(_buildBulletSprite),

        // FX under player
        ...controller.gifFxs.where((fx) => !fx.onTop).map(_buildFxSprite),

        // Powerups
        ...controller.powerups.map(_buildPowerUpSprite),

        // Player
        _buildPlayerSprite(),

        // FX on top of player
        ...controller.gifFxs.where((fx) => fx.onTop).map(_buildFxSprite),
      ],
    );
  }

  // ---- SPRITES ----

  Widget _buildEnemySprite(Enemy en) {
    final imagePath = (en is Asteroid) ? Assets.asteroid : Assets.enemyAlien;
    return _Sprite(
      imagePath: imagePath,
      center: en.position,
      size: en.size,
    );
  }

  Widget _buildEnemyHpBar(Enemy en) {                
    final double w = en.size.width;
    const double h = 6.0;
    final double ratio = _safeRatio(en.hp, en.maxHp);

    return Positioned(
      left: en.position.dx - w / 2,
      top: en.position.dy - en.size.height / 2 - 8,
      width: w,
      height: h,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSprite(Bullet b) {              
    return _Sprite(
      imagePath: b.asset,                            
      center: b.position,
      size: b.size,
      crisp: true,
    );
  }

  Widget _buildPowerUpSprite(PowerUp p) {          
    return _Sprite(
      imagePath: Assets.powerUpBox,
      center: p.position,
      size: const Size(40, 40),
    );
  }

  Widget _buildPlayerSprite() {
    return _Sprite(
      imagePath: controller.currentShipAsset,
      center: controller.player.position,
      size: controller.player.size,
    );
  }

  Widget _buildFxSprite(TimedGifFx fx) {          
    return _Sprite(
      imagePath: fx.asset,
      center: fx.position,
      size: fx.size,
    );
  }

  double _safeRatio(num a, num b) {
    if (b == 0) return 0.0;
    final r = a / b;
    if (r.isNaN || r.isInfinite) return 0.0;
    return r.clamp(0.0, 1.0).toDouble();
  }
}

class _Sprite extends StatelessWidget {
  final String imagePath;
  final Offset center;
  final Size size;
  final bool crisp;

  const _Sprite({
    required this.imagePath,
    required this.center,
    required this.size,
    this.crisp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: crisp ? FilterQuality.none : FilterQuality.low,
        gaplessPlayback: true,
        errorBuilder: (_, err, __) {
          debugPrint('Missing asset: $imagePath -> $err');
          return Container(color: Colors.pinkAccent.withOpacity(0.35)); 
        },
      ),
    );
  }
}
