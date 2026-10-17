import 'dart:math' as math;

import 'package:devxsd_gamejam/game/camera_rig.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flutter_test/flutter_test.dart';

double activeCenter(PuzzleModel model) =>
    model.activeCells.fold<double>(0, (sum, cell) => sum + cell.row) /
        model.activeCells.length -
    model.riseProgress;

void main() {
  test('begins below spawning piece and bounds camera travel', () {
    final rig = CameraRig();
    expect(rig.focusRow, 42.5);
    rig.reset(activeRow: 40, pieceSerial: 1);
    expect(rig.focusRow, 42);
    rig.update(activeRow: -100, pieceSerial: 2, dt: 0);
    expect(rig.focusRow, 2);
    rig.update(activeRow: 100, pieceSerial: 3, dt: 0);
    expect(rig.focusRow, 43);
  });

  test('normal ascent follows smoothly without overshoot or landing input', () {
    final rig = CameraRig()..reset(activeRow: 40, pieceSerial: 1);
    var previous = rig.focusRow;
    for (var i = 1; i <= 600; i++) {
      final row = 40 - i / 60;
      rig.update(activeRow: row, pieceSerial: 1, dt: 1 / 60);
      expect(rig.focusRow, lessThanOrEqualTo(previous));
      expect(rig.focusRow, greaterThanOrEqualTo(row + 2));
      expect(rig.focusRow - (row + 2), lessThan(0.2));
      previous = rig.focusRow;
    }
  });

  test('accelerated ascent remains continuous and contact settles gently', () {
    final rig = CameraRig()..reset(activeRow: 40, pieceSerial: 1);
    var previous = rig.focusRow;
    for (var i = 1; i <= 120; i++) {
      final row = 40 - i / 5; // Twelve rows per second.
      rig.update(activeRow: row, pieceSerial: 1, dt: 1 / 60);
      expect((rig.focusRow - previous).abs(), lessThanOrEqualTo(0.200000001));
      expect(rig.focusRow - (row + 2), lessThan(2.2));
      previous = rig.focusRow;
    }
    final atContact = rig.focusRow;
    rig.update(activeRow: 16, pieceSerial: 1, dt: 0.5);
    expect(rig.focusRow, greaterThan(18));
    expect(rig.focusRow, lessThan(atContact));
    expect(rig.focusRow, closeTo(18, 0.14));
  });

  test('exponential tracking is independent of frame partition', () {
    final first = CameraRig()..reset(activeRow: 40, pieceSerial: 1);
    final second = CameraRig()..reset(activeRow: 40, pieceSerial: 1);
    first.update(activeRow: 39, pieceSerial: 1, dt: 0.5);
    for (var i = 0; i < 30; i++) {
      second.update(activeRow: 39, pieceSerial: 1, dt: 1 / 60);
    }
    expect(first.focusRow, closeTo(second.focusRow, 1e-9));
    expect(first.focusRow, closeTo(41 + math.exp(-0.5 / 0.18), 1e-9));
  });

  test('new spawn immediately returns to base even with zero frame time', () {
    final rig = CameraRig()..reset(activeRow: 1, pieceSerial: 7);
    rig.update(activeRow: 40.5, pieceSerial: 8, dt: 0);
    expect(rig.focusRow, 42.5);
    rig.reset(activeRow: 40, pieceSerial: 9);
    expect(rig.focusRow, 42);
    rig.update(activeRow: 40, pieceSerial: 9, dt: 0.1);
    expect(rig.focusRow, 42);
  });

  test(
    'actual ascent, contact and hard launch track spawn serial consistently',
    () {
      final model = PuzzleModel(seed: 7);
      final rig = CameraRig();
      final serial = model.pieceSerial;
      rig.reset(activeRow: activeCenter(model), pieceSerial: serial);
      for (var i = 0; i < 900 && model.pieceSerial == serial; i++) {
        model.update(0.05);
        rig.update(
          activeRow: activeCenter(model),
          pieceSerial: model.pieceSerial,
          dt: 0.05,
        );
        expect(rig.focusRow.isFinite, isTrue);
      }
      expect(model.pieceSerial, serial + 1);
      expect(rig.focusRow, activeCenter(model) + 2);
      model.hardDrop();
      rig.update(
        activeRow: activeCenter(model),
        pieceSerial: model.pieceSerial,
        dt: 0,
      );
      expect(model.pieceSerial, serial + 2);
      expect(rig.focusRow, activeCenter(model) + 2);
      model.reset();
      expect(model.pieceSerial, serial + 3);
    },
  );

  test(
    'high-level accelerated ascent keeps bounded readable camera distance',
    () {
      final model = PuzzleModel(seed: 19)..rings = 100;
      model.softDrop = true;
      final rig = CameraRig()
        ..reset(activeRow: activeCenter(model), pieceSerial: model.pieceSerial);
      var serial = model.pieceSerial;
      var ascentFrames = 0;
      for (var frame = 0; frame < 120; frame++) {
        model.update(1 / 60);
        rig.update(
          activeRow: activeCenter(model),
          pieceSerial: model.pieceSerial,
          dt: 1 / 60,
        );
        final target = (activeCenter(model) + 2).clamp(2.0, 43.0);
        expect(rig.focusRow - target, lessThanOrEqualTo(2.000000001));
        if (model.pieceSerial != serial) {
          expect(rig.focusRow, target);
          serial = model.pieceSerial;
        } else {
          ascentFrames++;
        }
      }
      expect(ascentFrames, greaterThan(60));
    },
  );

  test('invalid samples cannot poison the camera', () {
    final rig = CameraRig()..reset(pieceSerial: 1);
    rig.update(activeRow: double.nan, pieceSerial: 1, dt: 0.1);
    rig.update(activeRow: 20, pieceSerial: 1, dt: double.infinity);
    rig.update(activeRow: 20, pieceSerial: 1, dt: -1);
    expect(rig.focusRow, 42.5);
  });
}
