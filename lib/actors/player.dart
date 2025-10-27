import 'dart:ui';
import '../core/entity.dart';
import '../core/interfaces.dart';
import '../combat/bullet_player.dart';
import '../util/game_tuning.dart';

class Player extends Entity implements IDamageable, IShootable {
  @override int maxHp = 100;

  int _hp = 100;
  @override int get hp => _hp;
   set hp(int value) {
    final newHp = value.clamp(0, maxHp);
    if (newHp < _hp && bulletLevel > minBulletLevel) {
      bulletLevel = (bulletLevel - 1).clamp(minBulletLevel, maxBulletLevel);
      _updateAmmoStats(); 
    }
    _hp = newHp;
    if (_hp == 0) dead = true;
  }

  static const int maxShield = 3;
  int shield = 0;
  void addShield([int n = 1]) {
    shield = ((shield + n).clamp(0, maxShield)).toInt();
  }

  static const int minBulletLevel = 1;
  static const int maxBulletLevel = 6; 

  double _shootCd = 0.0;
  
  // HỆ THỐNG CẤP ĐẠN MỚI
  int _currentAmmo = 0;
  int get currentAmmo => _currentAmmo;
  int get ammoLimit => GameTuning.getAmmoLevelInfo(bulletLevel)['limit'];
  int get bulletDamage => GameTuning.getAmmoLevelInfo(bulletLevel)['damage'];
  int get fireRate => GameTuning.getAmmoLevelInfo(bulletLevel)['fireRate'];
  
  int bulletLevel = minBulletLevel;

  Player({required super.position})
      : super(id: nextId('p'), size: GameTuning.playerSize) {
    _resetAmmo(); 
  }

  void resetToBaseStats() {
    maxHp = 100;
    hp = maxHp;
    shield = 0;
    bulletLevel = minBulletLevel;
    _resetAmmo(); 
    dead = false;
    _shootCd = 0;
  }

  void _resetAmmo() {
    _currentAmmo = ammoLimit;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shootCd > 0) _shootCd -= dt;
  }

  bool canShoot() => _shootCd <= 0 && _currentAmmo > 0;
  
  void _resetShootCd() => _shootCd = 1 / (fireRate > 0 ? fireRate : 1);

  void upgradeBulletLevel([int by = 1]) {
    final newLevel = (bulletLevel + by).clamp(minBulletLevel, maxBulletLevel);
    if (newLevel != bulletLevel) {
      bulletLevel = newLevel;
      _resetAmmo(); 
    }
  }

  int addAmmo(int amount) {
    final before = _currentAmmo;
    _currentAmmo = (_currentAmmo + amount).clamp(0, ammoLimit);
    return _currentAmmo - before;
  }

  @override
  void takeDamage(int dmg) {
    if (dmg <= 0 || dead) return;
    if (shield > 0) {
      shield = (shield - 1).clamp(0, maxShield);
      return;
    }
    hp = hp - dmg;
  }
  @override
  bool get isDead => dead;

   @override
  void shoot(void Function(Entity e) spawn) {
    if (!canShoot()) return;

    _currentAmmo--;
    _resetShootCd();

    final int n = bulletLevel.clamp(minBulletLevel, maxBulletLevel);
    final double spacing = GameTuning.sx(GameTuning.bulletSpacingX);
    final double muzzleUp = GameTuning.sx(GameTuning.gunMuzzleOffsetY);

    final double half = (n - 1) / 2.0;
    final double y = position.dy - muzzleUp;

    for (int i = 0; i < n; i++) {
      final double dx = (i - half) * spacing;
      spawn(PlayerBullet(
        position: Offset(position.dx + dx, y),
        dmg: bulletDamage, 
      ));
    }
  }

  bool get isLowHp   => (hp / maxHp) < GameTuning.lowResourceThreshold;
  bool get isLowAmmo => (ammoLimit == 0)
      ? true
      : (_currentAmmo / ammoLimit) < GameTuning.lowResourceThreshold;

  bool get isMaxBulletLevel => bulletLevel >= maxBulletLevel;
  void _updateAmmoStats() { }
}