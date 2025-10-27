import 'package:flutter/material.dart';

import '../assets.dart';
import '../services/bgm_service.dart';
import 'options_screen.dart';
import 'game/game_screen.dart';
import '../systems/score_manager.dart';
import '../widgets/score_item.dart';
import '../models/high_score.dart';
import '../util/game_tuning.dart';
import '../util/math_ext.dart'; // clampDouble
import '../services/sfx_service.dart';
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ===== State =====
  String _selectedShip = Assets.player;
  bool _audioUnlocked = false;

  late final ScoreManager _scoreManager;
  final List<HighScore> _topScores = [];
  String _playerName = 'Player';

  // Responsive constants
  static const double _centerMaxWidth = 440;
  static const double _rankMinWidth = 320;
  static const double _rankMaxWidth = 460;
  static const double _rankSideBreakpoint = 900; // >= thì RANK ở bên phải

  @override
  void initState() {
    super.initState();
    _scoreManager = ScoreManager();
    _initializeScores();
  }

  Future<void> _initializeScores() async {
    try {
      await _scoreManager.loadScores();
      if (!mounted) return;
      setState(() {
        _topScores
          ..clear()
          ..addAll(_scoreManager.getTopScores(10));
      });
    } catch (e) {
      debugPrint('Error loading scores: $e');
    }
  }

  void _unlockAudio() {
    if (_audioUnlocked) return;
    _audioUnlocked = true;
    SfxService.I.init();
    BgmService.I
      ..setMuted(false)
      ..startLoop(); // ✅ nhạc menu (không restart nếu đã chạy)
  }

  Future<void> _showNameInputDialog() async {
    final c = TextEditingController(text: _playerName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('NHẬP TÊN NGƯỜI CHƠI',
            style: TextStyle(fontFamily: Assets.titleFontFamily,color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: 'Nhập tên của bạn...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 16),
          maxLength: 15,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('HỦY', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = c.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('BẮT ĐẦU'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _playerName = result);
      await _startGame();
    }
  }

  Future<void> _startGame() async {
    //  chuyển sang nhạc game 1 lần trước khi vào game
    await BgmService.I.playGameLoop();
    if (!mounted) return;

    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          selectedShip: _selectedShip,
          playerName: _playerName,
        ),
      ),
    );

    if (!mounted) return;
    //  quay về menu -> đảm bảo nhạc menu, không restart nếu đang chạy
    await BgmService.I.startLoop();
    _initializeScores();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: dùng kích thước "an toàn" (đã trừ notch/status bar) để tránh overflow
    final win = MediaQuery.sizeOf(context);
    final pad = MediaQuery.viewPaddingOf(context);
    final safeSize = Size(
      (win.width  - pad.left - pad.right).clamp(0, double.infinity),
      (win.height - pad.top  - pad.bottom).clamp(0, double.infinity),
    );
    GameTuning.setScaleBy(safeSize);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _unlockAudio(),
      onPointerHover: (_) => _unlockAudio(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: Image.asset(Assets.bg, fit: BoxFit.cover)),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(GameTuning.sx(20)),
                child: _buildMenuLayout(safeSize), // FIX: truyền safeSize
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== LAYOUT  (responsive) ======
  Widget _buildMenuLayout(Size size) {
    final bool sideRank = size.width >= _rankSideBreakpoint;
    final bool isShort  = size.height < 720; // FIX: coi là màn thấp

    // FIX: scale tàu theo cạnh ngắn màn hình để không vượt chiều cao
    final shipSide =
        clampDouble(size.shortestSide * 0.40, 110.0, sideRank ? 220.0 : 180.0);

    final centerColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(),
        SizedBox(height: GameTuning.sx(28)),
        _menuButton(
          label: 'PLAY',
          onPressed: () async {
            _unlockAudio();
            await _showNameInputDialog();
          },
        ),
        SizedBox(height: GameTuning.sx(14)),
        _menuButton(
          label: 'OPTIONS',
          onPressed: () async {
            await BgmService.I.startLoop();
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => OptionsScreen(initialShip: _selectedShip),
              ),
            );
            if (!mounted) return;
            if (result != null) setState(() => _selectedShip = result);
          },
        ),
        SizedBox(height: GameTuning.sx(18)),
        ShipPreviewBox(
          asset: _selectedShip,
          maxSize: shipSide, // FIX
        ),
      ],
    );

    final centerBlock = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _centerMaxWidth),
        // FIX: nếu màn thấp thì cho cuộn để không overflow
        child: isShort ? SingleChildScrollView(child: centerColumn) : centerColumn,
      ),
    );

    final rankPanel = _TopScoresPanel(scores: _topScores);

    if (sideRank) {
      final rankWidth =
          clampDouble(size.width * 0.34, _rankMinWidth, _rankMaxWidth);
      final rankHeight = size.height - GameTuning.sx(40);
      return Row(
        children: [
          Expanded(child: centerBlock),
          SizedBox(width: GameTuning.sx(16)),
          SizedBox(width: rankWidth, height: rankHeight, child: rankPanel),
        ],
      );
    } else {
      // FIX: hạ tỉ lệ & min để nhường chỗ cho phần trên trên màn thấp
      final rankHeight = clampDouble(size.height * 0.33, 200.0, 360.0);
      return Column(
        children: [
          Expanded(child: centerBlock),
          SizedBox(height: GameTuning.sx(12)), // FIX: giảm khoảng cách
          SizedBox(height: rankHeight, child: rankPanel),
        ],
      );
    }
  }

  // ===== Helpers =====
  Widget _title() {
    const title = 'SPACE INVADER'; 
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: Assets.titleFontFamily,
        fontSize: GameTuning.font(48),
        color: Colors.white,
        letterSpacing: 2,
        shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
      ),
    );
  }
  Widget _menuButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: GameTuning.sx(240),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: GameTuning.sx(12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black87, width: 1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: GameTuning.font(20),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ===== Widgets con =====

class ShipPreviewBox extends StatelessWidget {
  final String asset;
  final double maxSize;
  const ShipPreviewBox({super.key, required this.asset, required this.maxSize});

  @override
  Widget build(BuildContext context) {
    final side = clampDouble(maxSize, 120.0, 260.0);
    return Padding(
      padding: EdgeInsets.only(bottom: GameTuning.sx(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: side, maxHeight: side),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: EdgeInsets.all(GameTuning.sx(12)),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24, width: 1.2),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset(asset),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopScoresPanel extends StatelessWidget {
  final List<HighScore> scores;
  const _TopScoresPanel({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RANK TOP 10',
            style: TextStyle(
              fontFamily: Assets.titleFontFamily,
              fontSize: GameTuning.font(20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: scores.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có điểm số!\nHãy chơi để lập kỷ lục!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (_, i) =>
                        ScoreItem(score: scores[i], rank: i + 1),
                  ),
          ),
        ],
      ),
    );
  }
}
