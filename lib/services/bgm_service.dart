import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../assets.dart';

class BgmService {
  BgmService._();
  static final BgmService I = BgmService._();

  final AudioPlayer _player = AudioPlayer();

  bool _inited = false;
  bool muted = false;
  double _musicVolume = 0.9;
  String? _currentAsset;

  bool _isPlaying = false;

  Future<void> _ensureInit() async {
    if (_inited) return;
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(muted ? 0.0 : _musicVolume);

    _player.onPlayerStateChanged.listen((s) {
      _isPlaying = (s == PlayerState.playing);
    });

    _inited = true;
  }

  Future<void> startLoop() async => _play(Assets.bgmMenu);

  Future<void> playGameLoop() async => _play(Assets.bgmGame);

  Future<void> _play(String assetPath) async {
    await _ensureInit();
    if (muted) return;

    if (_currentAsset == assetPath && _isPlaying) {
      await _player.setVolume(_musicVolume);
      return;
    }

    if (_currentAsset != assetPath) {
      _currentAsset = assetPath;
      try { await _player.stop(); } catch (_) {}
      await _setSourceWithWebFallback(assetPath);
    }

    if (!_isPlaying) {
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(_musicVolume);
        await _player.resume();
      } catch (_) {}
    }
  }

  Future<void> _setSourceWithWebFallback(String asset) async {
    try {
      await _player.setSource(AssetSource(asset));
    } catch (_) {
      if (kIsWeb && asset.endsWith('.mp3')) {
        final ogg = asset.replaceFirst('.mp3', '.ogg');
        await _player.setSource(AssetSource(ogg));
        _currentAsset = ogg;
      } else {
        rethrow;
      }
    }
  }

  Future<void> setMuted(bool m) async {
    muted = m;
    await _player.setVolume(m ? 0.0 : _musicVolume);
    if (m) {
      try { await _player.pause(); } catch (_) {}
    } else {

      if (_currentAsset != null && !_isPlaying) {
        try { await _player.resume(); } catch (_) {}
      } else if (_currentAsset == null) {
        await startLoop();
      }
    }
  }

  void setVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    if (!muted) {
      _player.setVolume(_musicVolume);
    }
  }
}
