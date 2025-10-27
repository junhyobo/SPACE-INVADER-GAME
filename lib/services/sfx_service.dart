import 'package:audioplayers/audioplayers.dart';
import '../assets.dart';

class SfxService {
  SfxService._();
  static final SfxService I = SfxService._();

  bool muted = false;
  double _sfxVolume = 0.7;
  double _vol(double mult) => muted ? 0.0 : (_sfxVolume * mult).clamp(0.0, 1.0);

  // Pool bắn hơi rộng để không “kẹt” khi bắn nhanh
  final List<AudioPlayer> _shootPool = List.generate(6, (_) => AudioPlayer());
  int _shootIdx = 0;

  final AudioPlayer _explosion = AudioPlayer();
  final AudioPlayer _shield    = AudioPlayer();
  final AudioPlayer _pickup    = AudioPlayer();
  final AudioPlayer _warning   = AudioPlayer();
  final AudioPlayer _combo     = AudioPlayer();

  bool _inited = false;
  static bool _ctxSet = false;

  Future<void> init() => _init();

  Future<void> _init() async {
    if (_inited) return;

    // CHỈ cấu hình AudioContext TOÀN CỤC ở đây (BgmService KHÔNG set nữa)
    if (!_ctxSet) {
      await AudioPlayer.global.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          isSpeakerphoneOn: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: [AVAudioSessionOptions.mixWithOthers],
        ),
      ));
      _ctxSet = true;
    }

    // Pool shoot (preload + warm-up)
    for (final p in _shootPool) {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource(Assets.sfxShoot));
      await _warmUp(p);
    }

    // Các SFX khác
    for (final p in [_explosion, _shield, _pickup, _warning, _combo]) {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
    }
    await _explosion.setSource(AssetSource(Assets.sfxExplosion));
    await _shield.setSource(AssetSource(Assets.sfxShieldBreak));
    await _pickup.setSource(AssetSource(Assets.sfxPickup));
    await _warning.setSource(AssetSource(Assets.sfxWarning));
    await _combo.setSource(AssetSource(Assets.sfxCombo));

    await _warmUp(_explosion);
    await _warmUp(_shield);
    await _warmUp(_pickup);
    await _warmUp(_warning);
    await _warmUp(_combo);

    _inited = true;
  }

  // Làm ấm decoder: phát câm 1 tick để lần sau không delay
  Future<void> _warmUp(AudioPlayer p) async {
    await p.setVolume(0);
    await p.resume();
    await p.pause();
    await p.seek(Duration.zero);
  }

  Future<void> setMuted(bool m) async { muted = m; }
  Future<void> setVolume(double v) async { _sfxVolume = v.clamp(0.0, 1.0); }

  // ====== Helpers: phát “an toàn” — không kẹt trạng thái ======
  void _fire(AudioPlayer p, String assetPath, double volMult) {
    if (muted || !_inited) return;

    // Reset state nhẹ nhưng “chắc”: PAUSE -> SEEK(0) -> RESUME
    p.setVolume(_vol(volMult));
    p.pause();
    p.seek(Duration.zero);
    p.resume().catchError((_) async {
      // Fallback hiếm gặp: nếu resume lỗi/không nổ, nạp lại nguồn một phát
      try {
        await p.stop();
        await p.setSource(AssetSource(assetPath));
        await p.resume();
      } catch (_) {}
    });
  }

  // ====== API phát SFX ======
  void playShoot() {
    final p = _shootPool[_shootIdx++ % _shootPool.length];
    _fire(p, Assets.sfxShoot, 0.25);
  }

  void playExplosion()    => _fire(_explosion, Assets.sfxExplosion, 0.65);
  void playShieldBreak()  => _fire(_shield,    Assets.sfxShieldBreak, 0.80);
  void playPickup()       => _fire(_pickup,    Assets.sfxPickup, 0.60);
  void playWarningSound() => _fire(_warning,   Assets.sfxWarning, 0.80);

  void Combo(int combo)   => _fire(_combo,     Assets.sfxCombo, 1.6);
}
