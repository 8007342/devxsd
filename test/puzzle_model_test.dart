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
  test('thirty-ring milestone continues play, speed increments diminish', () {
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
    expect(model.finished, isFalse);
    expect(model.won, isTrue);
    final elapsed = model.elapsed;
    model.update(3);
    expect(model.elapsed, greaterThan(elapsed));
    expect(model.thirtyRingTime, elapsed);
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
    expect(model.angle, .5);
    expect(model.bestColumn, 0);
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
  test(
    'gentle release snaps immediately and exactly while ascent continues',
    () {
      final model = PuzzleModel();
      model.debugSetActive(type: 3, column: 0, row: 30);
      model.beginDrag();
      model.dragColumns(0.24);
      model.releaseSpin(1.5);
      expect(model.spinVelocity, 0);
      model.update(0.12);
      expect(model.angle, 1);
      expect(model.riseProgress, closeTo(0.12, 1e-9));
    },
  );
  test(
    'fast flicks settle exactly within half a second in either direction',
    () {
      for (final velocity in [-40.0, -12.0, 12.0, 40.0]) {
        final model = PuzzleModel();
        model.debugSetActive(type: 3, column: 0, row: 30);
        model.beginDrag();
        model.dragColumns(0.23);
        final releasedAt = model.angle;
        model.releaseSpin(velocity);
        model.update(0.45);
        expect(model.spinVelocity, 0);
        expect(model.angle, model.angle.roundToDouble());
        expect((model.angle - releasedAt).sign, velocity.sign);
        expect(model.riseProgress, closeTo(0.45, 1e-9));
      }
    },
  );
  test('a new drag interrupts both coast and final snapping', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 3, column: 0, row: 30);
    model.releaseSpin(20);
    model.update(0.1);
    model.beginDrag();
    final held = model.angle;
    model.update(0.2);
    expect(model.angle, held);
    model.dragColumns(0.2);
    model.releaseSpin(0);
    model.update(0.01);
    model.beginDrag();
    final snappingInterrupted = model.angle;
    model.update(0.2);
    expect(model.angle, snappingInterrupted);
  });
  test('flick into obstacle snaps to legal side without tunnelling', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 20);
    model.board[20][4] = 7;
    model.releaseSpin(40);
    model.update(0.45);
    expect(model.spinVelocity, 0);
    expect(model.angle, model.activeCenterColumn);
    expect(model.bestColumn, 2);
    expect(
      model.activeCells.every(
        (cell) => model.board[cell.row][cell.column] == 0,
      ),
      isTrue,
    );
    final stopped = model.angle;
    model.beginDrag();
    model.dragColumns(-2);
    expect(model.angle, stopped - 2);
  });
  test('settled ages follow survivors through compaction and reset', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 2, column: 0, row: 20);
    model.hardDrop();
    expect(model.settledAge(1, 0), 0);
    model.update(2);
    expect(model.settledAge(1, 0), closeTo(2, 1e-9));
    expect(model.settledAge(5, 0), 0);
    for (var column = 2; column < 18; column++) {
      model.board[0][column] = 7;
    }
    model.debugSetActive(type: 1, column: 4, row: 20);
    model.hardDrop();
    expect(model.rings, 1);
    expect(model.board[0][0], 2);
    expect(model.settledAge(0, 0), closeTo(2, 1e-9));
    expect(model.board[0][4], 1);
    expect(model.settledAge(0, 4), 0);
    expect(model.settledAge(1, 0), 0);
    model.update(0.25);
    expect(model.settledAge(0, 0), closeTo(2.25, 1e-9));
    expect(model.settledAge(0, 4), closeTo(0.25, 1e-9));
    model.reset();
    expect(model.settledAge(0, 0), 0);
    expect(model.settledAge(0, 4), 0);
  });
  test('direct column input interrupts a stale snap target', () {
    final model = PuzzleModel();
    model.debugSetActive(type: 3, column: 0, row: 30);
    model.dragColumns(0.3);
    model.releaseSpin(0);
    model.update(0.01);
    model.dragColumns(1);
    model.releaseSpin(0);
    model.update(0.12);
    expect(model.angle, 2);
    expect(model.spinVelocity, 0);
  });
  test(
    'settled fixture ages can predate the run and clearing removes them',
    () {
      final model = PuzzleModel();
      model.debugSetSettled(row: 0, column: 17, type: 3, age: 25);
      expect(model.elapsed, 0);
      expect(model.settledAge(0, -1), 25);
      model.update(0.25);
      expect(model.settledAge(0, 17), closeTo(25.25, 1e-9));
      model.debugSetSettled(row: 0, column: 17, type: 0);
      expect(model.settledAge(0, 17), 0);
      model.board[0][17] =
          5; // Unstamped fixture cells do not inherit removed ages.
      expect(model.settledAge(0, 17), 0);
    },
  );
}
