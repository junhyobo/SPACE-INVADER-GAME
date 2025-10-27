import 'dart:ui';

class InputSystem {
  /// Vị trí mục tiêu (chuột hoặc ngón chạm #1)
  Offset target = Offset.zero;

  /// Trạng thái tác vụ
  bool moveActive = false;   // đang điều khiển di chuyển (primary)
  bool fireActive = false;   // đang bắn (secondary hoặc chuột trái)

  /// Cập nhật mục tiêu, tự kẹp trong vùng chơi
  void setTarget(Offset newPos, Size playArea, {double pad = 16}) {
    target = Offset(
      newPos.dx.clamp(pad, playArea.width - pad),
      newPos.dy.clamp(pad, playArea.height - pad),
    );
  }

  void setMoveActive(bool v) => moveActive = v;
  void setFireActive(bool v) => fireActive = v;

  void reset() {
    moveActive = false;
    fireActive = false;
  }
}
