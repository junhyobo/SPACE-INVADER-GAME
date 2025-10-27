import '../util/game_tuning.dart';

class HighScore {
  final int score;
  final String date;
  final String playerName;
  final String avatar;

  HighScore({
    required this.score,
    required this.date,
    required this.playerName,
    required this.avatar,
  });

  // Fallback duy nhất: thiếu avatar -> dùng tàu mặc định
  static String _normalizeAvatar(String? raw) {
    if (raw == null || raw.isEmpty) {
      return GameTuning.defaultShip;
    }
    return raw;
  }

  factory HighScore.fromMap(Map<String, dynamic> map) {
    return HighScore(
      score: map['score'] ?? 0,
      date: map['date'] ?? '',
      playerName: map['playerName'] ?? 'Player',
      avatar: _normalizeAvatar(map['avatar'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
    'score': score,
    'date': date,
    'playerName': playerName,
    'avatar': avatar,
  };

  String toStorageString() => '$score|$date|$playerName|$avatar';

  factory HighScore.fromStorageString(String storageString) {
    final parts = storageString.split('|');
    return HighScore(
      score: int.tryParse(parts[0]) ?? 0,
      date: parts.length > 1 ? parts[1] : '',
      playerName: parts.length > 2 ? parts[2] : 'Player',
      avatar: _normalizeAvatar(parts.length > 3 ? parts[3] : null),
    );
  }
}
