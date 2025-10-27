import 'dart:math' as math;
import 'dart:math' show Random;

/// Linear interpolation (0..1)
double lerp(double a, double b, double t) => a + (b - a) * t;

/// Clamp t vào [0, 1] — TRẢ VỀ double, tránh num->double
double clamp01(double t) => t < 0.0 ? 0.0 : (t > 1.0 ? 1.0 : t);

/// Clamp v vào [lo, hi] — TRẢ VỀ double
double clampDouble(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// min/max cho double
double minD(double a, double b) => a < b ? a : b;
double maxD(double a, double b) => a > b ? a : b;

/// Ánh xạ [v] từ [inMin..inMax] sang [outMin..outMax] (có thể clamp)
double mapRange(
  double v,
  double inMin,
  double inMax,
  double outMin,
  double outMax, {
  bool clamp = false,
}) {
  if (inMax == inMin) return outMin;
  final t = (v - inMin) / (inMax - inMin);
  final tt = clamp ? clamp01(t) : t;
  return lerp(outMin, outMax, tt);
}
/// Hệ số smooth-follow độc lập FPS: smoothing ~ 0.85, dt = giây
double smoothFollowFactor(double smoothing, double dt) {
  final num sNum = 1 - math.pow(1 - smoothing, dt * 60);
  final double s = sNum.toDouble();
  return clamp01(s);
}

/// Damping tiến về target (xịn hơn lerp cố định)
double damp(double current, double target, double smoothing, double dt) {
  final f = smoothFollowFactor(smoothing, dt);
  return lerp(current, target, f);
}

/// Mỗi frame tiến gần target tối đa [maxDelta]
double approach(double current, double target, double maxDelta) {
  final delta = target - current;
  if (delta.abs() <= maxDelta) return target;
  return current + maxDelta * (delta.isNegative ? -1.0 : 1.0);
}

// random trong khoảng [a, b] (double) ====
double randRange(Random rng, double a, double b) => a + rng.nextDouble() * (b - a);
