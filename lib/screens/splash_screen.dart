import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../assets.dart';
import '../services/bgm_service.dart';
import 'menu_screen.dart'; 
import '../services/sfx_service.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _t;
  bool _ready = false;
  bool _didPrecache = false;

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
    SfxService.I.init(); // idempotent
  });
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _t = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
    _ac.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _ready = true);
    });
    _ac.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage(Assets.bg), context);
      precacheImage(const AssetImage(Assets.bg2), context);
      precacheImage(const AssetImage(Assets.load), context);
      precacheImage(AssetImage(Assets.bulletPlayer), context);
      precacheImage(AssetImage(Assets.bulletEnemy), context);
    });
    _didPrecache = true;
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    try {
      await BgmService.I.setMuted(false);
      await BgmService.I.startLoop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MenuScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        //  Nền
        const IgnorePointer(
          ignoring: true,
          child: Image(
            image: AssetImage(Assets.bg),
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //  Thanh load có tàu bay
                AnimatedBuilder(
                  animation: _t,
                  builder: (_, __) => ShipProgressBarSlim(progress: _t.value),
                ),
                const SizedBox(height: 8),
                //  Nút START 
                if (_ready)
                  SizedBox(
                    width: 150,
                    child: _StartButton(
                      text: 'START',
                      onPressed: _go,
                      height: 50,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// =====================
/// Thanh tiến trình load + tàu bay
/// =====================
class ShipProgressBarSlim extends StatelessWidget {
  final double progress;
  const ShipProgressBarSlim({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxBarW = 520.0;
    final barW = math.min(size.width * 0.9, maxBarW); // <= 90% chiều ngang, tối đa 520
    final barH = 12.0;
    final shipW = math.max(56.0, barW * 0.18);
    final shipH = shipW;

    final p = progress.clamp(0.0, 1.0);
    final fillW = barW * p;
    final shipLeft = (fillW - shipW / 2).clamp(0.0, barW - shipW);

    return SizedBox(
      width: barW,
      height: math.max(barH, shipH),
      child: Stack(children: [
        Align(
          alignment: Alignment.center,
          child: CustomPaint(size: Size(barW, barH), painter: _SlimBarPainter(progress: p)),
        ),
        Positioned(
          left: shipLeft,
          top: (math.max(barH, shipH) - shipH) / 2,
          width: shipW,
          height: shipH,
          child: Image.asset(Assets.load, fit: BoxFit.contain),
        ),
      ]),
    );
  }
}

class _SlimBarPainter extends CustomPainter {
  final double progress;
  const _SlimBarPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final trackRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), r);

    final track = Paint()..color = const Color(0xFFEFEFF7);
    canvas.drawRRect(trackRect, track);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.black;
    canvas.drawRRect(trackRect, border);

    final fillW = size.width * progress;
    if (fillW > 0) {
      final fillRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, fillW, size.height), r);
      final shader = const LinearGradient(
        colors: [Color(0xFFFFC107), Color(0xFFE53935), Color(0xFF7B41FF), Color(0xFF4BC7FF)],
      ).createShader(Rect.fromLTWH(0, 0, fillW, size.height));
      final pFill = Paint()..shader = shader;
      canvas.drawRRect(fillRect, pFill);
    }
  }

  @override
  bool shouldRepaint(covariant _SlimBarPainter old) => old.progress != progress;
}

/// =====================
///  Nút START có hiệu ứng quét sáng
/// =====================
class _StartButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  const _StartButton({required this.text, required this.onPressed, this.height = 48});
  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        final pos = _shineController.value;
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha:0.9),
                Colors.transparent,
              ],
              stops: [(pos - 0.2).clamp(0.0, 1.0), pos, (pos + 0.2).clamp(0.0, 1.0)],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha:.35),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB0E8FF), // xanh nhạt sáng
                  Color(0xFF74C9FF), // xanh lam nhẹ hơn
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha:0.7), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8022B3FF),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: Color.fromARGB(255, 255, 0, 0),
                  shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 8,
                    color: Color.fromARGB(255, 81, 91, 44),
                  ),
                  ]
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}