import 'dart:math';
import 'dart:ui';

import '../actors/enemy.dart';
import '../actors/alien_enemy.dart';
import '../actors/asteroid.dart';
import '../util/game_tuning.dart';
import '../util/math_ext.dart';

typedef SpawnFn = void Function(Enemy enemy);
typedef IsWaveClearFn = bool Function();

/// ===============================
/// HẰNG SỐ DÙNG RIÊNG CHO LEVEL
/// ===============================

// Ô tam giác cho ALIEN (tính cột)
const double _kEnemyW = 64, _kEnemyH = 64, _kEnemyMargin = 24;

// ALIEN: nhóm & nhịp (để gọn trong file này)
const List<int> _groupChoices = [2, 3, 4, 5];
const double _groupGapMin = 0.9;
const double _groupGapMax = 1.6;
const double _staggerMin  = 0.05;
const double _staggerMax  = 0.09;
const double _xWindowSec  = 0.9;

// ===================== METEOR (mưa xiên từ MÉP TRÁI, nhả theo burst) =====================
// Tổng số thiên thạch của stage & nhịp giữa các burst
const int    _meteorCount         = 20;     // số viên/stage (giữ nguyên tên)
const double _meteorIntervalFixed = 0.01;   // khoảng nghỉ giữa các burst

// Kích cỡ burst và biên độ vận tốc ngang (nhân với asteroidDirX)
const int    _meteorBatch   = 16;    // số viên mỗi burst (có thể tinh chỉnh)
const double _meteorVxMinMul = 0.75; // vx = asteroidDirX * [min..max]
const double _meteorVxMaxMul = 1.55;

int _alienCountForPhase(int phase) {
  switch (phase) {
    case 0: return 12;
    case 1: return 15;
    case 2: return 20;
    default: return 12;
  }
}

class LevelManager {
  final _rng = Random();

  // ===== Stage & phase =====
  int stage = 1;
  int get _phase => (stage - 1) % 4;
  bool get _meteorMode => _phase == 3;

  // ===== Kích thước màn =====
  double _screenWidth  = 400;
  double _screenHeight = 700;
  void setScreenWidth(double w)  => _screenWidth  = w;
  void setScreenHeight(double h) => _screenHeight = h;

  // ===== Tam giác spawn alien =====
  double _spawnBaseY = -40;
  double _spawnCenterX = 200;
  void setSpawnBaseY(double y) => _spawnBaseY = y;
  void setSpawnCenterX(double x) => _spawnCenterX = x;

  // ===== Spacing theo scale =====
  double spacingX = GameTuning.sx(_kEnemyW + _kEnemyMargin);
  double spacingY = GameTuning.sx(_kEnemyH + _kEnemyMargin);

  // ===== ALIEN: hàng đợi & chống trùng X =====
  final List<Offset> _pendingPts = [];
  final List<_RecentX> _recentX = [];

  // ===== ALIEN: theo dõi wave =====
  int _spawnedThisWave = 0;
  int _targetThisWave  = 0;

  // ===== ALIEN: nhóm + stagger =====
  final List<Offset> _staggerQueue = [];
  double _groupTimer   = 0.0;
  double _staggerTimer = 0.0;
  int _lastGroupSize   = 0;     // nhóm sau ≥ nhóm trước

  // ===== METEOR: theo kiểu queue + burst (port từ code 1) =====
  final List<_AstOrder> _astQueue = [];
  double _astTimer = 0.0;
  bool _meteorFirstBurstDone = false;

  LevelManager() { _buildForStage(); }

  void reset() {
    stage = 1;

    spacingX = GameTuning.sx(_kEnemyW + _kEnemyMargin);
    spacingY = GameTuning.sx(_kEnemyH + _kEnemyMargin);

    _pendingPts.clear();
    _recentX.clear();
    _staggerQueue.clear();
    _groupTimer = 0.0;
    _staggerTimer = 0.0;
    _spawnedThisWave = 0;
    _targetThisWave = 0;
    _lastGroupSize = 0;

    _astQueue.clear();
    _astTimer = 0.0;
    _meteorFirstBurstDone = false;

    _buildForStage();
  }

  void rebuildForCurrentStage() {
    spacingX = GameTuning.sx(_kEnemyW + _kEnemyMargin);
    spacingY = GameTuning.sx(_kEnemyH + _kEnemyMargin);

    _pendingPts.clear();
    _recentX.clear();
    _staggerQueue.clear();
    _groupTimer = 0.0;
    _staggerTimer = 0.0;
    _spawnedThisWave = 0;
    _targetThisWave = 0;
    _lastGroupSize = 0;

    _astQueue.clear();
    _astTimer = 0.0;
    _meteorFirstBurstDone = false;

    _buildForStage();
  }

  // ===================================================================
  // Update
  // ===================================================================
  void update(double dt, SpawnFn onSpawn, IsWaveClearFn isWaveCleared) {
    _tickRecentX(dt);

    if (_meteorMode) {
      _updateMeteor(dt, onSpawn, isWaveCleared);
      return;
    }

    // ---------- ALIEN ----------
    if (_staggerQueue.isNotEmpty) {
      _staggerTimer -= dt;
      if (_staggerTimer <= 0) {
        final pos = _staggerQueue.removeAt(0);
        _spawnAlienAt(onSpawn, pos);
        _spawnedThisWave++;
        _staggerTimer = _rand(_staggerMin, _staggerMax);
      }
    } else if (_pendingPts.isNotEmpty) {
      _groupTimer -= dt;
      if (_groupTimer <= 0) {
        final remain = _pendingPts.length;
        final gSize  = _pickGroupSizeMonotonic(remain);
        for (int i = 0; i < gSize; i++) {
          final p = _takeNextOffsetRespectDX();
          if (p == null) break;
          _staggerQueue.add(p);
        }
        _staggerTimer  = _rand(_staggerMin, _staggerMax);
        _groupTimer    = _rand(_groupGapMin, _groupGapMax);
        _lastGroupSize = gSize;
      }
    }

    if (_spawnedThisWave >= _targetThisWave &&
        _staggerQueue.isEmpty &&
        _pendingPts.isEmpty &&
        isWaveCleared()) {
      stage += 1;
      rebuildForCurrentStage();
    }
  }

  // ===================================================================
  // METEOR: Hàng đợi + burst, spawn từ mép trái ngoài màn → bay xiên
  // ===================================================================
  void _updateMeteor(double dt, SpawnFn onSpawn, IsWaveClearFn isWaveCleared) {
    if (!_meteorFirstBurstDone) {
      // Nhả ngay burst đầu
      for (int k = 0; k < _meteorBatch && _astQueue.isNotEmpty; k++) {
        final o = _astQueue.removeAt(0);
        final meteorHp = (GameTuning.lvlAlienBaseHp * GameTuning.lvlMeteorHpMult).round();
        onSpawn(
          Asteroid(position: o.pos, dirX: o.dirX)
            ..speed = GameTuning.asteroidSpeedY
            ..maxHp = meteorHp
            ..hp    = meteorHp,
        );
      }
      _meteorFirstBurstDone = true;
      _astTimer = _meteorIntervalFixed;
    } else {
      _astTimer -= dt;
      if (_astTimer <= 0) {
        for (int k = 0; k < _meteorBatch && _astQueue.isNotEmpty; k++) {
          final o = _astQueue.removeAt(0);
          final meteorHp = (GameTuning.lvlAlienBaseHp * GameTuning.lvlMeteorHpMult).round();
          onSpawn(
            Asteroid(position: o.pos, dirX: o.dirX)
              ..speed = GameTuning.asteroidSpeedY
              ..maxHp = meteorHp
              ..hp    = meteorHp,
          );
        }
        _astTimer = _meteorIntervalFixed;
      }
    }

    if (_astQueue.isEmpty && isWaveCleared()) {
      stage += 1;
      rebuildForCurrentStage();
    }
  }

// Tạo queue thiên thạch xuất phát từ mép TRÁI ngoài màn, bay ngang sang phải
void _enqueueMeteorShower({required int count}) {
  _astQueue.clear();

  final baseOffX = -120.0; // LUÔN từ trái
  final vxMin = GameTuning.asteroidDirX * _meteorVxMinMul;
  final vxMax = GameTuning.asteroidDirX * _meteorVxMaxMul;

  // Ép spawn từ TRÊN như quái thường
   final startYBase = GameTuning.screenTopLimit; 
  const gapY = 100.0;       

  for (int i = 0; i < count; i++) {
    final offJitterX = _rng.nextDouble() * 60 - 30; 
    final offX = baseOffX + offJitterX;

    // Y bắt đầu từ trên mép màn + stagger
    final yJitter = _rng.nextDouble() * 60 - 30;
    final y = startYBase - i * gapY + yJitter;

    // LUÔN bay sang phải (vx dương)
    final vx = vxMin + _rng.nextDouble() * (vxMax - vxMin);

    _astQueue.add(_AstOrder(Offset(offX, y), vx));
  }

  _astTimer = 0.0;
}
  // ===================================================================
  // Build stage
  // ===================================================================
 void _buildForStage() {
  if (_meteorMode) {
    _enqueueMeteorShower(count: _meteorCount);
    _astTimer = 0.0;
    _meteorFirstBurstDone = false;
    return;
  }

  final int n = _alienCountForPhase(_phase);
  _targetThisWave = n;
  _spawnedThisWave = 0;

  // >>> clamp X sau khi jitter để không tràn mép
  final halfW = GameTuning.sz(GameTuning.alienSize).width / 2;
  final double minX = halfW + 8;
  final double maxX = _screenWidth - halfW - 8;
  _pendingPts
  ..clear()
  ..addAll(_triangle(n).map((p) {
    final jx   = (_rng.nextDouble() * 2 - 1) * GameTuning.lvlSpawnJitterX;

    final nx = (p.dx + jx).clamp(minX, maxX);
    final ny = p.dy - GameTuning.lvlSpawnTopOffset;

    return Offset(nx, ny);
  }));
_pendingPts.shuffle(_rng);
  _staggerQueue.clear();
  _groupTimer   = 0.0;
  _staggerTimer = 0.0;
  _recentX.clear();
  _lastGroupSize = 0;
}

  // ================= ALIEN helpers =================
  int _pickGroupSizeMonotonic(int remain) {
    final options  = _groupChoices.where((g) => g >= _lastGroupSize).toList();
    final baseList = options.isNotEmpty ? options : _groupChoices;
    final pick     = baseList[_rng.nextInt(baseList.length)];
    return pick.clamp(1, remain);
  }

  Offset? _takeNextOffsetRespectDX() {
    if (_pendingPts.isEmpty) return null;
    for (int i = 0; i < _pendingPts.length; i++) {
      final cand = _pendingPts[i];
      if (_isFarEnoughX(cand.dx)) {
        _pendingPts.removeAt(i);
        _rememberX(cand.dx);
        return cand;
      }
    }
    final pos = _pendingPts.removeAt(0);
    _rememberX(pos.dx);
    return pos;
  }

  bool _isFarEnoughX(double x) {
    for (final r in _recentX) {
      if ((x - r.x).abs() < GameTuning.lvlSpawnMinDX) return false;
    }
    return true;
  }

  void _rememberX(double x) {
    _recentX.add(_RecentX(x, _xWindowSec));
  }

  void _tickRecentX(double dt) {
    for (final r in _recentX) { r.ttl -= dt; }
    _recentX.removeWhere((r) => r.ttl <= 0);
  }

  // ================= Tam giác alien =================
  List<Offset> _triangle(int n) {
    final pts = <Offset>[];

    int rows = 1;
    while ((rows * (rows + 1)) ~/ 2 < n) { rows++; }

    final halfW = GameTuning.sx(_kEnemyW) / 2;
    final minX = halfW + 8;
    final maxX = _screenWidth - halfW - 8;

    int placed = 0;
    for (int r = rows; r >= 1 && placed < n; r--) {
      final countThisRow = min(r, n - placed);

      final usableWidth  = (maxX - minX);
      final desiredWidth = (countThisRow - 1) * spacingX;
      final sx = (countThisRow > 1 && desiredWidth > usableWidth)
          ? usableWidth / (countThisRow - 1)
          : spacingX;

      final rowWidth = (countThisRow - 1) * sx;
      double startX  = _spawnCenterX - rowWidth / 2;
      if (startX < minX) startX = minX;
      if (startX + rowWidth > maxX) startX = maxX - rowWidth;

      final y = _spawnBaseY + (rows - r) * spacingY;

      for (int i = 0; i < countThisRow && placed < n; i++) {
        final x = startX + i * sx;
        pts.add(Offset(x, y));
        placed++;
      }
    }
    return pts;
  }

  // ================= Spawn 1 alien =================
  void _spawnAlienAt(SpawnFn onSpawn, Offset base) {
    onSpawn(
      AlienEnemy(position: base)
        ..speed = GameTuning.alienSpeedY
        ..amp   = (58 + _rng.nextInt(6)).toDouble()
        ..maxHp = GameTuning.lvlAlienBaseHp
        ..hp    = GameTuning.lvlAlienBaseHp
        ..t     = _rng.nextDouble() * 6.283
        ..freq  = 1.5 + _rng.nextDouble() * 0.6,
    );
  }

  // ================= Utils =================
  double _rand(double a, double b) => a + _rng.nextDouble() * (b - a);
}

class _RecentX {
  double x;
  double ttl;
  _RecentX(this.x, this.ttl);
}

class _AstOrder {
  final Offset pos;
  final double dirX;
  _AstOrder(this.pos, this.dirX);
}
