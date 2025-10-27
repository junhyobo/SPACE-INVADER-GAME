import 'package:flutter/material.dart';
import '../assets.dart';
import '../util/game_tuning.dart'; // IMPORT GAME_TUNING

class ShipSelectScreen extends StatefulWidget {
  final String initialShip;
  const ShipSelectScreen({super.key, required this.initialShip});

  @override
  State<ShipSelectScreen> createState() => _ShipSelectScreenState();
}

class _ShipSelectScreenState extends State<ShipSelectScreen> {
  late final List<Map<String, dynamic>> ships;
  late int _index;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    // DÙNG KÍCH THƯỚC TỪ GAME_TUNING
    ships = [
      {
        'asset': Assets.player,
        'size': GameTuning.shipSelectSize1, 
      },
      {
        'asset': Assets.player2,
        'size': GameTuning.shipSelectSize2, 
      },
      {
        'asset': Assets.player3,
        'size': GameTuning.shipSelectSize3, 
      },
    ];

    // tìm index khớp initialShip
    _index = ships.indexWhere((ship) => ship['asset'] == widget.initialShip);
    if (_index < 0) _index = 0;

    _pageCtrl = PageController(
      initialPage: _index,
      viewportFraction: 0.72,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(AssetImage(Assets.bg2), context);
      for (final ship in ships) {
        precacheImage(AssetImage(ship['asset']), context);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    if (!mounted) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ships[_index]['asset'];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.bg2, fit: BoxFit.cover),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  tooltip: 'Exit',
                  onPressed: () => Navigator.pop(context, widget.initialShip),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha:0.25),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 320,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: PageView.builder(
                              controller: _pageCtrl,
                              itemCount: ships.length,
                              onPageChanged: _onPageChanged,
                              itemBuilder: (_, i) {
                                final isSel = i == _index;
                                final ship = ships[i];
                                
                                return Center(
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    scale: isSel ? 1.25 : 0.95,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 180),
                                      opacity: isSel ? 1 : 0.6,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        // DÙNG KÍCH THƯỚC TỪ GAME_TUNING
                                        child: SizedBox(
                                          width: ship['size'],
                                          height: ship['size'],
                                          child: Image.asset(
                                            ship['asset'],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Nút trái
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _chevronButton(
                                isLeft: true,
                                onTap: () {
                                  final prev = (_index - 1 + ships.length) % ships.length;
                                  _pageCtrl.animateToPage(
                                    prev,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Nút phải
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _chevronButton(
                                isLeft: false,
                                onTap: () {
                                  final next = (_index + 1) % ships.length;
                                  _pageCtrl.animateToPage(
                                    next,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, selected),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Select', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevronButton({
    required bool isLeft,
    required VoidCallback onTap,
  }) {
    const double visualSize = 88;
    const double hitPadding = 16;
    const double stroke = 12;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(hitPadding),
          color: Colors.transparent,
          child: SizedBox(
            width: visualSize,
            height: visualSize,
            child: CustomPaint(
              painter: _ChevronPainter(
                isLeft: isLeft,
                color: const Color.fromARGB(255, 100, 231, 176),
                strokeWidth: stroke,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final bool isLeft;
  final Color color;
  final double strokeWidth;

  _ChevronPainter({
    required this.isLeft,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pad = strokeWidth;
    final start = Offset(isLeft ? size.width - pad : pad, pad);
    final mid   = Offset(isLeft ? pad : size.width - pad, size.height / 2);
    final end   = Offset(isLeft ? size.width - pad : pad, size.height - pad);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) =>
      old.isLeft != isLeft ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}