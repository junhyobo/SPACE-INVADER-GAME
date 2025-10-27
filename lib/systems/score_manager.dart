import 'package:flutter/foundation.dart';
import '../models/high_score.dart';
import '../services/storage_service.dart';
import '../util/game_tuning.dart';

class ScoreManager {
  final StorageService _storage = StorageService.I;
  final List<HighScore> _scores = [];

  /// Nạp toàn bộ điểm đã lưu (nếu có)
  Future<void> loadScores() async {
    try {
      final saved = await _storage.loadString(GameTuning.highScoresKey);
      _scores.clear();
      if (saved == null || saved.trim().isEmpty) return;

      for (final line in saved.split('\n')) {
        final s = line.trim();
        if (s.isEmpty) continue;
        try {
          _scores.add(HighScore.fromStorageString(s));
        } catch (e) {
          debugPrint('Skip bad highscore line: $s ($e)');
        }
      }
      _scores.sort((a, b) => b.score.compareTo(a.score));
    } catch (e) {
      debugPrint('Error loading scores: $e');
    }
  }

  /// Thêm một score MỚI vào danh sách hiện có rồi lưu lại
  Future<void> addScore(HighScore newScore) async {
    // Quan trọng: nạp list hiện có để tránh ghi đè
    await loadScores();

    _scores.add(newScore);
    _scores.sort((a, b) => b.score.compareTo(a.score));

    // Giữ tối đa 100 bản ghi
    if (_scores.length > 100) {
      _scores.removeRange(100, _scores.length);
    }

    await _saveScores();
  }

  /// Trả về top N (read-only)
  List<HighScore> getTopScores(int count) {
    final end = count < _scores.length ? count : _scores.length;
    return List.unmodifiable(_scores.sublist(0, end));
  }

  Future<void> _saveScores() async {
    try {
      final data = _scores.map((e) => e.toStorageString()).join('\n');
      await _storage.saveString(GameTuning.highScoresKey, data);
    } catch (e) {
      debugPrint('Error saving scores: $e');
    }
  }

  Future<void> clearScores() async {
    _scores.clear();
    await _storage.clearHighScores();
  }

  int get scoreCount => _scores.length;
}
