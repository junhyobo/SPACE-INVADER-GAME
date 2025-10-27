import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../assets.dart';
import '../services/bgm_service.dart';
import '../services/sfx_service.dart';
import 'how_to_play_screen.dart';
import 'ship_select_screen.dart';
import '../util/game_tuning.dart';
import '../util/math_ext.dart' as mx;

class OptionsScreen extends StatefulWidget {
  final String initialShip;
  final String backgroundAsset;
  const OptionsScreen({
    super.key,
    required this.initialShip,
    this.backgroundAsset = Assets.bg,
  });

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(widget.backgroundAsset), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.15)),
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, c) {
                final maxW = c.maxWidth;
                final maxH = c.maxHeight;
                final cardW = math.min(420.0, maxW - 24.0);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardW,
                      maxHeight: maxH - 24.0,
                    ),
                    child: _OptionsCard(initialShip: widget.initialShip),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsCard extends StatefulWidget {
  final String initialShip;
  const _OptionsCard({required this.initialShip});

  @override
  State<_OptionsCard> createState() => _OptionsCardState();
}

class _OptionsCardState extends State<_OptionsCard> {
  late String _selectedShip = widget.initialShip;

  double _music = GameTuning.defaultMusicVolume;
  double _sfx   = GameTuning.defaultSfxVolume;

  bool _bgmUnlocked = false;
  bool _musicWasZero = false;

  // ✅ chỉ unlock + phát nhạc menu đúng 1 lần đầu tiên
  Future<void> _unlockBgmOnce() async {
    if (_bgmUnlocked) return;
    _bgmUnlocked = true;
    await BgmService.I.setMuted(false);
    await BgmService.I.startLoop(); // nhạc menu; không restart nếu đang phát
  }

  void _onMusic(double v) {
    v = mx.clampDouble(v, 0.0, 1.0);
    setState(() => _music = v);

    if (v <= 0.0001) {
      if (!_musicWasZero) {
        _musicWasZero = true;
        BgmService.I.setMuted(true);
      }
      return;
    }

    if (_musicWasZero) {
      _musicWasZero = false;
      BgmService.I.setMuted(false);
    }
    if (!_bgmUnlocked) _unlockBgmOnce(); // đảm bảo đã phát menu ở lần đầu
    BgmService.I.setVolume(v);      // chỉ chỉnh volume, không phát lại
  }

  void _onMusicEnd(double v) {
    if (v > 0 && !_bgmUnlocked) _unlockBgmOnce();
  }

  void _onSfx(double v) {
    v = mx.clampDouble(v, 0.0, 1.0);
    setState(() => _sfx = v);
    if (v <= 0) {
      if (!SfxService.I.muted) SfxService.I.setMuted(true);
    } else {
      if (SfxService.I.muted) SfxService.I.setMuted(false);
      SfxService.I.setVolume(v);
    }
  }

  // ✅ KHÔNG cần gọi nhạc lại ở các UI phụ (nhạc menu đã chạy sẵn)
  Future<void> _openHowToPlay() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
    );
  }

  Future<void> _openSelectShip() async {
    if (!mounted) return;
    final res = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ShipSelectScreen(initialShip: _selectedShip)),
    );
    if (res != null && mounted) setState(() => _selectedShip = res);
  }

  void _close() => Navigator.of(context).pop(_selectedShip);

  @override
  Widget build(BuildContext context) {
    const r = 28.0;

    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .42),
                      Colors.white.withValues(alpha: .20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(r),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'OPTIONS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Assets.titleFontFamily,
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SettingsSliderRow(
                        icon: Icons.volume_up_rounded,
                        label: ' ',
                        value: _music,
                        onChanged: _onMusic,
                        onChangeEnd: _onMusicEnd,
                      ),
                      const SizedBox(height: 12),

                      _SettingsSliderRow(
                        icon: Icons.music_note_rounded,
                        label: ' ',
                        value: _sfx,
                        onChanged: _onSfx,
                      ),
                      const SizedBox(height: 18),

                      _CopperButton(text: 'How to Play', onPressed: _openHowToPlay),
                      const SizedBox(height: 12),

                      _CopperButton(text: 'Select Ship', onPressed: _openSelectShip),
                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: _close,
                        child: const Icon(Icons.close_rounded, size: 44, color: Color(0xFFE53935)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  foregroundPainter: _DashedRRectPainter(
                    radius: r,
                    color: Colors.black,
                    strokeWidth: 4,
                    dash: 10,
                    gap: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _SettingsSliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4423);
    const thumb = Color(0xFFFF8A00);
    const active = Color(0xFF76E17C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircleAvatar(
                backgroundColor: brown,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: active,
                  inactiveTrackColor: brown,
                  thumbColor: thumb,
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: mx.clampDouble(value, 0.0, 1.0),
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                  min: 0,
                  max: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CopperButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _CopperButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, minHeight: 44),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFC19A),
              Color(0xFFB86D49),
              Color(0xFFE1A37C),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFBFFB88),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final Color color;

  _DashedRRectPainter({
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dash, metric.length - distance);
        final segment = metric.extractPath(distance, distance + len);
        canvas.drawPath(segment, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap ||
      old.color != color;
}
