import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void clearRings(PuzzleModel model, int count) {
  for (var r = 0; r < 42; r++) {
    model.board[r].fillRange(0, 18, 0);
  }
  // A vertical I fills one missing column in up to four consecutive rings.
  for (var row = 0; row < count; row++) {
    model.board[row].fillRange(0, 18, 2);
    model.board[row][3] = 0;
  }
  model.debugSetActive(type: 1, column: 0, row: 10, rotation: 1);
  model.hardDrop();
}

void main() {
  test('gentle release preserves every shape, rotation and selected halo', () {
    for (var type = 1; type <= 7; type++) {
      for (var rotation = 0; rotation < 4; rotation++) {
        for (final column in [-19, -1, 0, 17, 18]) {
          for (final fraction in [-.49, -.01, 0.0, .01, .49]) {
            final model = PuzzleModel(seed: 9);
            model.debugSetActive(
              type: type,
              column: column,
              row: 25,
              rotation: rotation,
            );
            model.beginDrag();
            model.dragColumns(fraction);
            final selected = model.bestColumn;
            final halo = model.landingCells
                .map((c) => '${c.column}:${c.row}')
                .toList();
            model.releaseSpin(fraction.sign * 8);
            for (var frame = 0; frame < 20; frame++) {
              model.update(.01);
              expect(
                model.bestColumn,
                selected,
                reason:
                    'type $type rotation $rotation column $column phase $fraction',
              );
            }
            expect(model.angle, model.activeCenterColumn);
            expect(model.landingCells.map((c) => '${c.column}:${c.row}'), halo);
          }
        }
      }
    }
  });
  test(
    'keyboard visits every adjacent column after rotations and snap reversal',
    () {
      for (var type = 1; type <= 7; type++) {
        for (var rotation = 0; rotation < 4; rotation++) {
          for (final direction in [-1, 1]) {
            final model = PuzzleModel(seed: 7);
            model.debugSetActive(
              type: type,
              column: 17,
              row: 25,
              rotation: rotation,
            );
            model.rotatePiece(1);
            model.beginDrag();
            model.dragColumns(.49);
            model.releaseSpin(0);
            var previous = model.bestColumn;
            final visited = <int>{};
            for (var step = 0; step < 36; step++) {
              model.shiftColumn(direction);
              expect(model.bestColumn, PuzzleModel.wrap(previous + direction));
              visited.add(model.bestColumn);
              previous = model.bestColumn;
              model.update(.001);
            }
            expect(visited.length, 18);
            model.shiftColumn(-direction);
            expect(model.bestColumn, PuzzleModel.wrap(previous - direction));
          }
        }
      }
    },
  );
  test('keyboard blocks instead of skipping occupied neighboring column', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 20);
    model.board[20][2] = 7;
    model.shiftColumn(1);
    expect(model.bestColumn, 0);
    model.shiftColumn(-1);
    expect(model.bestColumn, 17);
    model.shiftColumn(1);
    expect(model.bestColumn, 0);
    model.board[20][2] = 0;
    model.shiftColumn(1);
    expect(model.bestColumn, 1);
  });
  test(
    'both entry modes retain first-thirty time through further clears and loss',
    () {
      for (final mode in GameMode.values) {
        final model = PuzzleModel(mode: mode, seed: 8)
          ..rings = 29
          ..elapsed = 100;
        clearRings(model, 2);
        expect(model.rings, 31);
        expect(model.thirtyRingTime, 100);
        expect(model.finished, isFalse);
        model.update(5);
        clearRings(model, 4);
        expect(model.rings, 35);
        expect(model.thirtyRingTime, 100);
        expect(model.plantHeight, 35);
        expect(model.elapsed, greaterThan(104));
        model.board[40].fillRange(0, 18, 7);
        model.board[40][17] = 0;
        model.debugSetActive(type: 2, column: 0, row: 5);
        model.hardDrop();
        expect(model.finished, isTrue);
        expect(model.thirtyRingTime, 100);
        final end = model.elapsed;
        model.update(5);
        expect(model.elapsed, end);
        model.reset();
        expect(model.thirtyRingTime, isNull);
        expect(model.leaves, isEmpty);
      }
    },
  );
  test('leaves open in stages, vary by run and reward multi-ring clears', () {
    final single = PuzzleModel(seed: 1)..elapsed = 10;
    final multi = PuzzleModel(seed: 1)..elapsed = 10;
    final other = PuzzleModel(seed: 2)..elapsed = 10;
    clearRings(single, 1);
    clearRings(multi, 3);
    clearRings(other, 1);
    expect(single.leaves.single.opening(10), 0);
    expect(single.leaves.single.opening(13), inExclusiveRange(0, 1));
    expect(single.leaves.single.opening(17), 1);
    expect(
      multi.leaves.first.matureScale,
      greaterThan(single.leaves.single.matureScale),
    );
    expect(multi.leaves.first.vigor, greaterThan(single.leaves.single.vigor));
    expect(
      other.leaves.single.variation,
      isNot(single.leaves.single.variation),
    );
    final earlyStem = multi.stemRows;
    for (var i = 0; i < 30; i++) {
      clearRings(multi, 4);
    }
    expect(multi.plantHeight, 123);
    expect(multi.leaves.length, lessThanOrEqualTo(40));
    expect(multi.leaves.last.node, 123);
    expect(multi.stemRows, greaterThan(earlyStem));
  });
}
