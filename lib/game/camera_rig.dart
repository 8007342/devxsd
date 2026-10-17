import 'dart:math' as math;

/// Ascent framing independent of projection and puzzle physics.
///
/// Rows grow downward. Following two rows below the active occupied center lets
/// the renderer place its eye farther below and aim up toward the stack.
class CameraRig {
  static const followTime = 0.18;
  static const followOffset = 2.0;
  static const maxFollowLag = 2.0;
  double _focusRow = 42.5;
  int? _pieceSerial;

  double get focusRow => _focusRow;

  double _target(double activeRow) =>
      (activeRow + followOffset).clamp(2.0, 43.0);

  void reset({double activeRow = 40.5, int? pieceSerial}) {
    if (!activeRow.isFinite) throw ArgumentError.value(activeRow, 'activeRow');
    _focusRow = _target(activeRow);
    _pieceSerial = pieceSerial;
  }

  void update({
    required double activeRow,
    required int pieceSerial,
    required double dt,
  }) {
    if (!activeRow.isFinite || !dt.isFinite || dt < 0) return;
    final target = _target(activeRow);
    if (_pieceSerial != pieceSerial) {
      // A motivated cut avoids sweeping down the entire board after each lock.
      _focusRow = target;
      _pieceSerial = pieceSerial;
      return;
    }
    _focusRow += (target - _focusRow) * (1 - math.exp(-dt / followTime));
    // Accelerated high-level play must retain the same readable local scale.
    _focusRow = math.min(_focusRow, target + maxFollowLag);
  }
}
