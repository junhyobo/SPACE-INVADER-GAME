// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../util/game_tuning.dart';

class StorageService {
  StorageService._internal();
  static final StorageService I = StorageService._internal();

  SharedPreferences? _prefs; // cache

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('StorageService.init() chưa được gọi');
    }
    return p;
  }

  // ===== High Scores (giữ lại API load/saveString để khớp ScoreManager) =====
  Future<String?> loadString(String key) async => _p.getString(key);
  Future<void> saveString(String key, String value) async => _p.setString(key, value);

  // ===== Audio Settings (SYNC + ASYNC để dùng linh hoạt) =====
  double getMusicVolumeSync() =>
      _p.getDouble(GameTuning.musicVolumeKey) ?? GameTuning.defaultMusicVolume;
  Future<double> getMusicVolume() async => getMusicVolumeSync();

  Future<void> setMusicVolume(double v) async =>
      _p.setDouble(GameTuning.musicVolumeKey, v);

  double getSfxVolumeSync() =>
      _p.getDouble(GameTuning.sfxVolumeKey) ?? GameTuning.defaultSfxVolume;
  Future<double> getSfxVolume() async => getSfxVolumeSync();

  Future<void> setSfxVolume(double v) async =>   _p.setDouble(GameTuning.sfxVolumeKey, v);

  // ===== Selected Ship =====
  String getSelectedShipSync() =>
      _p.getString(GameTuning.selectedShipKey) ?? GameTuning.defaultShip;
  Future<String> getSelectedShip() async => getSelectedShipSync();

  Future<void> setSelectedShip(String asset) async =>
      _p.setString(GameTuning.selectedShipKey, asset);

  // ===== Clear helpers =====
  Future<void> clearAllData() async => _p.clear();
  Future<void> clearHighScores() async => _p.remove(GameTuning.highScoresKey);
}
