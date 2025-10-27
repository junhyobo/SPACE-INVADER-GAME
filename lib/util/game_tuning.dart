import 'dart:ui';
import 'dart:math' as math;

class GameTuning {
  // ===== Padding gốc (đơn vị theo khung 400x700) =====
  static const double _kTopPad = 60;    // khoảng ngoài mép trên để spawn/ẩn
  static const double _kBottomPad = 80; // khoảng ngoài mép dưới để auto-huỷ
  static const double _kSidePad = 120;  // khoảng ngoài mép trái/phải

  // ===== Scale & helper =====
  static double scale = 1.0;                                 // hệ số co giãn tổng
  static Size sz(Size base) => Size(base.width * scale, base.height * scale); // scale cho Size
  static double sx(double v) => v * scale;                   // scale cho số đo 1 chiều
  static double font(double px) => (px * scale).clamp(px * 0.9, px * 1.4); // scale font, có kẹp biên
  static double v(double base) => base * (0.85 + 0.25 * scale);            // điều chỉnh “vận tốc/nhịp” theo scale

  // ===== Biên màn (động) — dùng để kiểm soát tràn =====
  // Khởi tạo tạm theo khung gốc; sau khi biết playArea thực tế sẽ cập nhật trong setScaleBy()
  static double screenLeftLimit   = -_kSidePad;
  static double screenTopLimit    = -_kTopPad;          // mép trên âm (spawn từ ngoài)
  static double screenBottomLimit = 700 + _kBottomPad;  // mép dưới > chiều cao -> rơi qua thì huỷ
  static double screenSideLimit   = 400 + _kSidePad;    // mép phải > bề rộng (mép trái dùng -sx(_kSidePad))

  /// Cập nhật scale + biên theo kích thước vùng chơi (đã trừ safe-area)
  static void setScaleBy(Size area) {
    // scale theo tỉ lệ khung gốc 400x700, kẹp từ 0.8..1.6 để không bị quá đà
    final s = math.min(area.width / 400.0, area.height / 700.0).clamp(0.8, 1.6);
    scale = (s as num).toDouble();

    // quy đổi padding gốc ra padding thực tế theo scale
    final topPad    = sx(_kTopPad);   // ví dụ 60 -> 60*scale
    final bottomPad = sx(_kBottomPad);
    final sidePad   = sx(_kSidePad);
    

    // ghi lại biên động để dùng ở mọi nơi (Enemy/Asteroid/HUD, v.v.)
    screenTopLimit    = -topPad;                // spawn “trên khỏi màn” một đoạn
    screenBottomLimit = area.height + bottomPad;// vượt quá đáy thì đánh dấu chết
    screenSideLimit   = area.width  + sidePad;  // biên phải; biên trái = -sidePad (tự suy ra khi dùng)
    screenLeftLimit   = -sidePad; 
  }

  // ===== Kích thước đối tượng gốc (trước khi scale) =====
  static const Size playerSize       = Size(120, 120); // tàu người chơi 
  static const Size alienSize        = Size(70, 70);   // alien 
  static const Size asteroidSize     = Size(122, 122); // thiên thạch 
  static const Size bulletPlayerSize = Size(50, 90);   // đạn người chơi 
  static const Size bulletEnemySize  = Size(42, 84);   // đạn địch 
  static const Size powerUpSize      = Size(80, 80);   // vật phẩm 

  // Kích thước preview tàu trong UI chọn tàu (không liên quan gameplay)
  static const double shipSelectSize1 = 180.0;
  static const double shipSelectSize2 = 180.0;
  static const double shipSelectSize3 = 180.0;

  // Kích thước hiệu ứng (FX) gốc
  static const Size fxHitSize         = Size(150, 150);
  static const Size fxShieldBreakSize = Size(100, 100);
  static const Size fxPickupSize      = Size(40, 40);

  // ===== Tham số gameplay cốt lõi =====
  // Người chơi
  static const int    playerCollisionDamage = 20; // sát thương khi va chạm thân
  static const int    playerFireRate        = 5;  // tốc độ bắn cơ sở (cấp 1)
  static const double playerPad             = 16; // khoảng đệm để không chạm sát mép

  // Đạn
  static const double bulletSpeedPlayer = -700; // âm = bay lên
  static const double bulletSpeedEnemy  = 320;  // dương = bay xuống

  // Quái / thiên thạch
  static const double alienSpeedY    = 60;   // rơi dọc ALIEN
  static const double asteroidSpeedY = 150;  // rơi dọc THIÊN THẠCH
  static const double asteroidDirX   = 80;   // vận tốc ngang cơ sở (THIÊN THẠCH sẽ nhân thêm tuỳ đợt)

  // Vật phẩm rơi
  static const double powerUpFallSpeed = 120; // tốc độ rơi vật phẩm
  static const double dropScale        = 0.3; // hệ số tần suất rơi chung
  static const double dropHealAlien    = 0.35; // tỉ lệ alien rơi máu
  static const double dropAmmoAlien    = 0.15; // tỉ lệ alien rơi đạn
  static const double dropHealAst      = 0.06; // tỉ lệ thiên thạch rơi máu
  static const double dropAmmoAst      = 0.05; // tỉ lệ thiên thạch rơi đạn

  // ===== Hệ thống đạn (cấp độ) =====
  static const int ammoTierStep  = 3;  // số level chơi thì tăng 1 bậc đạn 
  static const int ammoTierScale = 10; // hệ số cộng dồn khi lên bậc

  /// Bảng cấp đạn: limit = sức chứa, damage = sát thương/viên, fireRate = tốc độ bắn
  static const Map<int, Map<String, dynamic>> ammoLevels = {
    1: {'limit': 100, 'damage': 8,  'fireRate': 5},
    2: {'limit': 80,  'damage': 12, 'fireRate': 5},
    3: {'limit': 60,  'damage': 18, 'fireRate': 6},
    4: {'limit': 40,  'damage': 25, 'fireRate': 6},
    5: {'limit': 35,  'damage': 35, 'fireRate': 7},
    6: {'limit': 25,  'damage': 40, 'fireRate': 8},
  };

  static Map<String, dynamic> getAmmoLevelInfo(int level) {
    return ammoLevels[level] ?? ammoLevels[1]!; // fallback về cấp 1 nếu sai key
  }

  static int get maxAmmoLevel => 6; // mức cấp đạn tối đa hiện tại

  // Bắn hàng ngang (multi-shot) của player
  static double bulletSpacingX   = 10; // khoảng cách ngang giữa các viên trong 1 loạt
  static double gunMuzzleOffsetY = 36; // lệch “nòng súng” theo Y từ tâm tàu

  // ===== Điểm, combo & cảnh báo =====
  static const int    scoreBlockStep   = 20;    // bước chia mốc điểm
  static const int    scoreBlockScale  = 1000;  // quy mô 1 mốc điểm
  static const double comboTimeout     = 4.0;   // sau 4s không hạ địch -> reset combo
  static const double lowResourceThreshold = 0.20; // % ngưỡng thấp (đạn/máu) để bật cảnh báo

  // ===== Lưu trữ (SharedPreferences) =====
  static const String highScoresKey   = 'high_scores';   // key danh sách điểm cao
  static const String musicVolumeKey  = 'music_volume';  // key âm lượng nhạc
  static const String sfxVolumeKey    = 'sfx_volume';    // key âm lượng SFX
  static const String selectedShipKey = 'selected_ship'; // key tàu đã chọn

  static const double defaultMusicVolume = 0.35; // nhạc mặc định
  static const double defaultSfxVolume   = 0.7;  // SFX mặc định
  static const String defaultShip        = 'assets/images/1.png'; // fallback tàu

  // ===== Tham số chung cho bố cục level/wave =====
  static const double lvlSpawnMinDX      = 46.0; // khoảng cách  2 quái theo trục X 
  static const double lvlSpawnTopOffset  = 80.0; // đẩy Y spawn lên khỏi mép 
  static const double lvlSpawnJitterX    = 20.0; // random lệch X 

  static const int    lvlAlienBaseHp  = 30;  // HP gốc alien (mốc để scale thứ khác)
  static const double lvlMeteorHpMult = 3.0; // thiên thạch = 3x HP alien gốc
}
