import 'package:flutter/material.dart';
import '../../systems/controller/game_controller.dart';
import '../../enums.dart';
import '../../assets.dart';
class GameOverlays extends StatelessWidget {
  final GameController controller;
  final VoidCallback onReset;
  final VoidCallback onMenu;

  const GameOverlays({
    super.key,
    required this.controller,
    required this.onReset,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (controller.stage == GameStage.gameOver)
          _GameOverOverlay(
            score: controller.score.value,
            onReset: onReset,
            onMenu: onMenu,
          ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onReset;
  final VoidCallback onMenu;

  const _GameOverOverlay({
    required this.score,
    required this.onReset,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha:0.65),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontFamily: Assets.titleFontFamily,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'SCORE $score',
                  style: const TextStyle(fontFamily: Assets.titleFontFamily,fontSize: 22, fontWeight: FontWeight.w700, color: Colors.yellow),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlueAccent,
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.black87),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: onReset,
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlueAccent,
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.black87),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: onMenu,
                      child: const Text('Menu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}