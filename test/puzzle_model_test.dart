import 'package:flutter_test/flutter_test.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';

void main() {
  test('pieces wrap across the cylindrical seam and queue stays three', () {
    final model = PuzzleModel(seed: 1);
    model.debugSetActive(type: 1, column: 17, row: 40);
    expect(model.activeCells.map((c) => c.column), [17, 0, 1, 2]);
    final bag = <int>[];
    model.reset();
    for (var i = 0; i < 7; i++) {
      bag.add(model.activeType);
      model.dragColumns(4.0 * i);
      model.hardDrop();
      expect(model.nextPieces.length, 3);
    }
    expect(bag.toSet().length, 7);
  });
  test('hard launch exactly matches the halo and locks immediately', () {
    final model = PuzzleModel(seed: 2);
    model.debugSetActive(type: 2, column: 3, row: 40);
    model.board[3][3] = 7;
    final halo = model.landingCells;
    model.hardDrop();
    for (final cell in halo) {
      expect(model.board[cell.row][cell.column], 2);
    }
  });
  test('cleared rings pull lower rows upward, leaving upper rows fixed', () {
    final model = PuzzleModel(seed: 3);
    for (var c = 4; c < PuzzleModel.columns; c++) {
      model.board[0][c] = 2;
    }
    model.board[5][8] = 6;
    model.debugSetActive(type: 1, column: 0, row: 1);
    model.hardDrop();
    expect(model.rings, 1);
    expect(model.board[4][8], 6);
    expect(model.board[5][8], 0);
    expect(model.clearSerial, 1);
  });
  test(
    'large spin sweeps intermediate columns and can reverse around obstacle',
    () {
      final model = PuzzleModel();
      model.debugSetActive(type: 2, column: 0, row: 20);
      model.board[20][4] = 7;
      model.releaseSpin(30);
      model.dragColumns(12);
      expect(model.angle, 2.5);
      expect(model.spinVelocity, 0);
      expect(model.collisionBounce, lessThan(0));
      model.dragColumns(-15);
      expect(model.angle, -12.5);
      expect(
        model.activeCells.every((c) => model.board[c.row][c.column] == 0),
        isTrue,
      );
    },
  );
  test('natural contact waits, permits adjustment, and then locks', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 0);
    model.beginDrag();
    model.update(0.4);
    expect(model.board[0][0], 0);
    model.dragColumns(1);
    model.update(0.4);
    expect(model.board[0][1], 0);
    model.update(0.11);
    expect(model.board[0][1], 2);
  });
  test('ascent continues while spinning and soft drop accelerates it', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 40);
    model.releaseSpin(5);
    model.update(1.1);
    expect(model.activeCells.first.row, 39);
    model.softDrop = true;
    model.update(0.2);
    expect(model.activeCells.first.row, lessThan(39));
  });
  test('timed wins immediately at thirty, speed increments diminish', () {
    final model = PuzzleModel();
    model.rings = 29;
    final before = model.speed;
    model.rings = 30;
    final increment = model.speed - before;
    model.rings = 59;
    final later = model.speed;
    model.rings = 60;
    expect(model.speed - later, lessThan(increment));
    model.rings = 29;
    for (var c = 4; c < 18; c++) {
      model.board[0][c] = 1;
    }
    model.debugSetActive(type: 1, column: 0, row: 1);
    model.hardDrop();
    expect(model.rings, 30);
    expect(model.finished, isTrue);
    expect(model.won, isTrue);
    final elapsed = model.elapsed;
    model.update(3);
    expect(model.elapsed, elapsed);
  });
  test('blocked next spawn ends either mode without a timed win', () {
    for (final mode in GameMode.values) {
      final model = PuzzleModel(mode: mode);
      model.debugSetActive(type: 2, column: 0, row: 0);
      model.beginDrag();
      model.board[40].fillRange(0, 18, 7);
      model.board[40][17] = 0; // Prevent this obstruction clearing as a ring.
      model.hardDrop();
      expect(model.finished, isTrue);
      expect(model.won, isFalse);
    }
  });
  test('drag owns angle while ascent continues, release resumes snapping', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 40);
    model.releaseSpin(20);
    model.beginDrag();
    model.dragColumns(0.3);
    model.update(0.4);
    expect(model.angle, closeTo(0.8, 1e-9));
    expect(model.riseProgress, closeTo(0.4, 1e-9));
    expect(model.bestColumn, 0);
    model.releaseSpin(0);
    model.update(0.2);
    expect(model.angle, greaterThan(0.8));
    expect(model.riseProgress, closeTo(0.6, 1e-9));
    model.reset();
    expect(model.dragging, isFalse);
  });
  test('all seven natural spawns are in bounds with a three piece preview', () {
    final model = PuzzleModel(seed: 11);
    final seen = <int>{};
    for (var i = 0; i < 7; i++) {
      seen.add(model.activeType);
      expect(
        model.activeCells.every((cell) => cell.row >= 40 && cell.row < 42),
        isTrue,
      );
      expect(model.nextPieces.length, 3);
      model.hardDrop();
    }
    expect(seen.length, 7);
  });
  test('fifteen contact resets cannot stall a piece forever', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 0);
    model.beginDrag();
    for (var i = 0; i < 15; i++) {
      model.update(0.1);
      model.dragColumns(i.isEven ? 1 : -1);
      expect(model.contactTime, 0);
    }
    model.update(0.4);
    model.dragColumns(-1);
    expect(model.contactTime, closeTo(0.4, 1e-9));
    model.update(0.1);
    expect(model.board[0].where((cell) => cell != 0).length, 2);
  });
  test(
    'every rotated shape is centered about front without changing board yaw',
    () {
      for (var type = 1; type <= 7; type++) {
        for (var rotation = 0; rotation < 4; rotation++) {
          final model = PuzzleModel();
          model.debugSetActive(
            type: type,
            column: 17,
            row: 20,
            rotation: rotation,
          );
          expect(
            model.bestColumn,
            17,
          ); // Fixture columns remain explicit grid anchors.
          expect(model.angle, 17 + model.activeCenterOffset);
          model.beginDrag();
          model.dragColumns(-model.angle);
          expect(model.angle, 0);
          expect(
            model.activeCenterColumn.abs(),
            lessThanOrEqualTo(0.500000001),
          );
          final anchor = model.bestColumn;
          final offsets =
              model.activeCells
                  .map((cell) => (cell.column - anchor) % 18)
                  .toList()
                ..sort();
          expect((offsets.first + offsets.last) / 2, model.activeCenterOffset);
          model.rotatePiece(1);
          expect(
            model.angle,
            0,
          ); // Shape rotation does not rotate an unobstructed cylinder.
          expect(
            model.activeCenterColumn.abs(),
            lessThanOrEqualTo(0.500000001),
          );
          final halo = model.landingCells;
          model.hardDrop();
          for (final cell in halo) {
            expect(model.board[cell.row][cell.column], type);
          }
        }
      }
    },
  );
  test(
    'center-adjusted rotation validates its final occupied cells near obstacles',
    () {
      for (var type = 1; type <= 7; type++) {
        for (var rotation = 0; rotation < 4; rotation++) {
          for (var phase = 0; phase < 5; phase++) {
            final model = PuzzleModel();
            model.debugSetActive(
              type: type,
              column: 17,
              row: 20,
              rotation: rotation,
            );
            for (var row = 18; row < 26; row++) {
              for (var column = 0; column < 18; column++) {
                if ((row * 13 + column * 7 + phase) % 5 == 0) {
                  model.board[row][column] = 7;
                }
              }
            }
            for (final cell in model.activeCells) {
              model.board[cell.row][cell.column] = 0;
            }
            model.rotatePiece(1);
            for (final cell in model.activeCells) {
              expect(
                model.board[cell.row][cell.column],
                0,
                reason: 'Type $type rotation $rotation obstacle phase $phase',
              );
            }
          }
        }
      }
    },
  );
}
