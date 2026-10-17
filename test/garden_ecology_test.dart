import 'dart:ui';

import 'package:devxsd_gamejam/game/garden_ecology.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weathering is delayed, monotonic and bounded', () {
    expect(GardenEcology.weathering(0), 0);
    expect(GardenEcology.weathering(3), 0);
    expect(GardenEcology.weathering(20), greaterThan(0));
    expect(
      GardenEcology.weathering(40),
      greaterThan(GardenEcology.weathering(20)),
    );
    expect(GardenEcology.weathering(100000), 1);
  });

  test(
    'butterflies favor one or two with rare third and never exceed three',
    () {
      expect(GardenEcology.butterflyCount(0, 45), 0);
      var thirds = 0;
      final counts = <int>{};
      for (var second = 0; second < 480; second++) {
        final count = GardenEcology.butterflyCount(200, second.toDouble());
        counts.add(count);
        expect(count, inInclusiveRange(1, 3));
        if (count == 3) thirds++;
        expect(GardenEcology.butterflyCount(2, second.toDouble()), 1);
      }
      expect(counts, {1, 2, 3});
      expect(thirds / 480, lessThan(.05));
    },
  );

  test(
    'ecology projects roots only for occupied cells and handles empty board',
    () {
      final model = PuzzleModel(seed: 4);
      final calls = <Offset>[];
      final roots = <Offset>[];
      Offset project(
        double column,
        double row, {
        double radius = 1,
        double? centerRow,
      }) {
        calls.add(Offset(column, row));
        if (centerRow != null) roots.add(Offset(column, row));
        return Offset(column * 10, row * 10);
      }

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      GardenEcology.paintHalf(
        canvas,
        model: model,
        clock: 0,
        front: true,
        project: project,
        yaw: 0,
        unit: 10,
      );
      expect(calls, isEmpty);
      model.debugSetSettled(row: 12, column: 0, type: 1, age: 60);
      model.debugSetSettled(row: 8, column: 8, type: 2, age: 60);
      GardenEcology.paintHalf(
        canvas,
        model: model,
        clock: 60,
        front: true,
        project: project,
        yaw: 0,
        unit: 10,
      );
      expect(calls, isNotEmpty);
      expect(roots, isNotEmpty);
      for (final root in roots) {
        expect(model.board[root.dy.round()][root.dx.round()], greaterThan(0));
      }
      GardenEcology.paintHalf(
        canvas,
        model: model,
        clock: 60,
        front: false,
        project: project,
        yaw: 0,
        unit: 10,
      );
      GardenEcology.paintButterflies(
        canvas,
        plantBounds: const Rect.fromLTWH(20, 20, 60, 180),
        rings: 25,
        clock: 45,
      );
      for (final row in model.board) {
        row.fillRange(0, row.length, 0);
      }
      calls.clear();
      GardenEcology.paintHalf(
        canvas,
        model: model,
        clock: 60,
        front: true,
        project: project,
        yaw: 0,
        unit: 10,
      );
      expect(
        calls,
        isEmpty,
        reason: 'Cleared occupancy removes all attachments',
      );
      recorder.endRecording().dispose();
    },
  );
}
