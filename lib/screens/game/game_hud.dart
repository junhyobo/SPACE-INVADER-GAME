import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../systems/controller/game_controller.dart';
import '../../util/game_tuning.dart';
import '../../actors/player.dart';

class GameHUD extends StatelessWidget {
  final GameController controller;

  final bool showMobileUi;
  final VoidCallback? onExit;

  const GameHUD({
    super.key,
    required this.controller,
    this.showMobileUi = false,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildAmmoHUD(),

        Positioned(
          top: 10, left: 0, right: 20,
          child: SafeArea(child: _buildComboHUD()),
        ),

        Positioned(
          right: 20,
          bottom: 100,
          child: SafeArea(child: _buildToast()),
        ),

        Positioned(
          left: 16,
          top: 16,
          child: SafeArea(child: _buildTopLeftHUD()),
        ),

        Positioned(
          right: 20,
          top: 16,
          child: SafeArea(child: _buildTopRightHUD()),
        ),

       // Exit luôn hiển thị nếu có callback
        if (onExit != null) _exitButton(context),

      ],
    );
  }

  // ===== Exit button (gốc trên trái) =====
  Widget _exitButton(BuildContext context) {
    return Positioned(
      left: 12,
      top: 12,
      child: SafeArea(
        child: GestureDetector(
          onTap: onExit,
          child: Container(
            width: GameTuning.sx(44),
            height: GameTuning.sx(44),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: GameTuning.sx(2)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.close_rounded,
                size: GameTuning.sx(26), color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ====== phần HUD  ======
  Widget _buildAmmoHUD() {
    final player = controller.player;
    final int currentAmmo = player.currentAmmo;
    final int maxAmmo = player.ammoLimit;

    double ammoRatio = 0.0;
    if (maxAmmo > 0 && currentAmmo >= 0) {
      ammoRatio = currentAmmo / maxAmmo;
    }
    ammoRatio = ammoRatio.clamp(0.0, 1.0);
    if (ammoRatio.isNaN || ammoRatio.isInfinite) ammoRatio = 0.0;

    final isLowAmmo = ammoRatio < GameTuning.lowResourceThreshold;
    final tMs = DateTime.now().millisecondsSinceEpoch;
    final wave = (math.sin(tMs * 0.012) * 0.5 + 0.5);
    final blinkOpacity = isLowAmmo ? 0.3 + 0.7 * wave : 1.0;

    return Positioned(
      left: GameTuning.sx(20),
      bottom: GameTuning.sx(20),
      child: SafeArea(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: blinkOpacity,
          child: Container(
            padding: EdgeInsets.all(GameTuning.sx(8)),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: GameTuning.sx(2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: GameTuning.sx(70),
                  height: GameTuning.sx(70),
                  child: CircularProgressIndicator(
                    value: ammoRatio,
                    strokeWidth: GameTuning.sx(6),
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLowAmmo ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentAmmo',
                      style: TextStyle(
                        color: isLowAmmo ? Colors.red : Colors.white,
                        fontSize: GameTuning.font(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/$maxAmmo',
                      style: TextStyle(
                        color: isLowAmmo ? Colors.red : Colors.white70,
                        fontSize: GameTuning.font(12),
                      ),
                    ),
                    SizedBox(height: GameTuning.sx(2)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: GameTuning.sx(6),
                        vertical: GameTuning.sx(2),
                      ),
                      decoration: BoxDecoration(
                        color: isLowAmmo ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(GameTuning.sx(8)),
                      ),
                      child: Text(
                        'Lv.${player.bulletLevel}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: GameTuning.font(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildToast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: controller.uiToasts.map((toast) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Text(
            toast.text,
            style: TextStyle(
              color: toast.color,
              fontSize: GameTuning.font(12),
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopLeftHUD() {
    final p = controller.player;
    final hpRatio = (p.hp / p.maxHp).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('HP', style: _hudRedStyle),
          SizedBox(width: GameTuning.sx(16)),
          _buildHPBar(hpRatio),
        ]),
        SizedBox(height: GameTuning.sx(18)),
        Row(children: [
          Text('Shield', style: _hudRedStyle),
          SizedBox(width: GameTuning.sx(18)),
          Row(
            children: List.generate(Player.maxShield, (i) {
              final filled = i < controller.player.shield;
              return Padding(
                padding: EdgeInsets.only(right: GameTuning.sx(16)),
                child: _buildPentagon(filled),
              );
            }),
          ),
        ]),
      ],
    );
  }

  Widget _buildTopRightHUD() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Stage ${controller.levels.stage}', style: _hudRedStyle),
        SizedBox(height: GameTuning.sx(6)),
        Text('Score ${controller.score.value}', style: _hudRedStyle),
      ],
    );
  }

  Widget _buildHPBar(double ratio) {
    final double w = GameTuning.sx(210), h = GameTuning.sx(16), radius = GameTuning.sx(10);
    final isLowHp = ratio < GameTuning.lowResourceThreshold;
    final tMs = DateTime.now().millisecondsSinceEpoch;
    final wave = (math.sin(tMs * 0.012) * 0.5 + 0.5);
    final blinkOpacity = isLowHp ? 0.3 + 0.7 * wave : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: blinkOpacity,
      child: Stack(children: [
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0x22FF6F00),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: w * ratio,
          height: h,
          decoration: BoxDecoration(
            gradient: isLowHp
                ? const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF6B6B)])
                : const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF9800)]),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ]),
    );
  }

  Widget _buildComboHUD() {
    final n = controller.combo;
    if (n < 2) return const SizedBox.shrink();

    final max = GameTuning.comboTimeout;
    double ratio = (controller.comboTimer / max).clamp(0.0, 1.0);
    if (ratio.isNaN || ratio.isInfinite) ratio = 0.0;

    final danger = ratio < GameTuning.lowResourceThreshold;
    final tMs = DateTime.now().millisecondsSinceEpoch;
    final blink = danger ? 0.5 + 0.5 * math.sin(tMs * 0.018) : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: blink,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: GameTuning.sx(14), vertical: GameTuning.sx(8)),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.45),
            borderRadius: BorderRadius.circular(GameTuning.sx(12)),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: GameTuning.sx(2)),
              const Text(
                'COMBO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              Text(
                'x$n',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: GameTuning.font(22),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              SizedBox(height: GameTuning.sx(6)),
              SizedBox(
                width: GameTuning.sx(160),
                height: GameTuning.sx(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GameTuning.sx(4)),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      danger ? Colors.redAccent : Colors.lightBlueAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPentagon(bool filled) {
    return CustomPaint(
      size: Size(GameTuning.sx(26), GameTuning.sx(26)),
      painter: _PentagonPainter(fillAmount: filled ? 1 : 0),
    );
  }

  TextStyle get _hudRedStyle => TextStyle(
    fontSize: GameTuning.font(22),
    fontWeight: FontWeight.w800,
    color: const Color(0xFFE53935),
  );
}

class _PentagonPainter extends CustomPainter {
  final double fillAmount;
  const _PentagonPainter({required this.fillAmount});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = (w < h ? w : h) * 0.48;

    final path = Path();
    const n = 5;
    const startAng = -math.pi / 2;
    for (int i = 0; i < n; i++) {
      final ang = startAng + i * 2 * math.pi / n;
      final x = cx + r * math.cos(ang);
      final y = cy + r * math.sin(ang);
      if (i == 0) { path.moveTo(x, y); }
      else { path.lineTo(x, y); }
    }
    path.close();

    if (fillAmount > 0) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF00A3FF).withOpacity(0.85 * fillAmount);
      canvas.drawPath(path, fill);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF00A3FF);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PentagonPainter old) => old.fillAmount != fillAmount;
}
