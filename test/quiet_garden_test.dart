import 'dart:io';
import 'dart:ui' as ui;
import 'package:devxsd_gamejam/game/chandelier_game.dart';
import 'package:devxsd_gamejam/game/garden_backdrop.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:devxsd_gamejam/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> raster(void Function(Canvas) paint, {String? file}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(390, 844);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  if (file != null) {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(file).parent.create(recursive: true);
    await File(file).writeAsBytes(png!.buffer.asUint8List());
  }
  image.dispose();
  picture.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'repeated rotations and simulation never turn an unobstructed cylinder',
    () {
      for (var type = 1; type <= 7; type++) {
        for (var rotation = 0; rotation < 4; rotation++) {
          for (final direction in [-1, 1]) {
            for (final column in [-19, -1, 0, 17, 18]) {
              final model = PuzzleModel(seed: 42);
              model.debugSetActive(
                type: type,
                column: column,
                row: 30,
                rotation: rotation,
              );
              final yaw = model.angle;
              final initialColumn = model.bestColumn;
              for (var turn = 0; turn < 12; turn++) {
                model.rotatePiece(direction);
                // A tap releases the cylinder before rotating; keyboard doesn't.
                if (turn.isEven) model.releaseSpin(0);
                for (var frame = 0; frame < 12; frame++) {
                  model.update(1 / 120);
                  expect(
                    model.angle,
                    yaw,
                    reason:
                        'type $type rotation $rotation turn $turn column $column',
                  );
                }
                if (turn % 4 == 3) expect(model.bestColumn, initialColumn);
              }
              model.shiftColumn(direction);
              expect(
                model.bestColumn,
                PuzzleModel.wrap(initialColumn + direction),
              );
              expect(model.angle, yaw + direction);
            }
          }
        }
      }
    },
  );
  test(
    'rotating while a fractional snap settles does not accumulate phase drift',
    () {
      final model = PuzzleModel(seed: 4);
      model.debugSetActive(type: 1, column: 17, row: 30);
      model.beginDrag();
      model.dragColumns(.31);
      model.releaseSpin(0);
      model.rotatePiece(1);
      model.update(.2);
      final snapped = model.angle;
      for (var turn = 0; turn < 20; turn++) {
        model.rotatePiece(1);
        model.update(.15);
        expect(model.angle, snapped);
      }
    },
  );
  testWidgets(
    'one quiet entry and scoreboard, with absolute rings and no live timer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChandelierApp());
      expect(find.text('Grow a garden'), findsOneWidget);
      expect(find.text('30-ring sprint'), findsNothing);
      expect(find.text('Endless garden'), findsNothing);
      await tester.tap(find.text('THE TOP TEN'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('30 Rings'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.tap(find.text('Grow a garden'));
      await tester.pump();
      final game =
          tester
                  .widget<GameWidget>(
                    find.byWidgetPredicate((w) => w is GameWidget),
                  )
                  .game
              as ChandelierGame;
      game.model.rings = 27;
      game.model.elapsed = 123;
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('27 Rings'), findsOneWidget);
      expect(find.text('TIME'), findsNothing);
      expect(find.text('30 RINGS'), findsNothing);
      expect(find.textContaining('/ 30'), findsNothing);
      expect(find.textContaining('02:03'), findsNothing);
      game.model.thirtyRingTime = 123;
      game.model.rings = 31;
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('31 Rings'), findsOneWidget);
      expect(find.textContaining('02:03'), findsNothing);
      // Exercise the actual keyboard path with time advanced after each key.
      game.model.debugSetActive(type: 1, column: 0, row: 30);
      final angle = game.model.angle;
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        game.update(.1);
        expect(game.model.angle, angle);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('side-tap rotations keep cylinder yaw after delayed snapping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChandelierApp());
    await tester.tap(find.text('Grow a garden'));
    await tester.pump();
    final game =
        tester
                .widget<GameWidget>(
                  find.byWidgetPredicate((w) => w is GameWidget),
                )
                .game
            as ChandelierGame;
    game.model.debugSetActive(type: 1, column: 17, row: 30);
    final yaw = game.model.angle;
    for (final side in [80.0, 300.0]) {
      for (var turn = 0; turn < 8; turn++) {
        await tester.tapAt(Offset(side, 380));
        await tester.pump(const Duration(milliseconds: 120));
        game.update(.12);
        expect(game.model.angle, yaw);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'ambient layers move independently without input with bounded speeds',
    () {
      const size = Size(390, 844);
      for (var layer = 0; layer < 3; layer++) {
        final first = GardenBackdrop.layerOffset(layer, 0, 0, size);
        expect(GardenBackdrop.layerOffset(layer, 60, 0, size), isNot(first));
        for (var second = 0; second < 1440; second++) {
          final a = GardenBackdrop.layerOffset(
            layer,
            second.toDouble(),
            0,
            size,
          );
          final b = GardenBackdrop.layerOffset(layer, second + 1.0, 0, size);
          expect((b - a).distance, lessThan(.3));
          expect(a.dx.abs(), lessThan(5));
          expect(a.dy.abs(), lessThan(3));
        }
      }
      expect(GardenBackdrop.tint(0), GardenBackdrop.tint(720));
      expect(GardenBackdrop.tint(0), isNot(GardenBackdrop.tint(180)));
    },
  );
  test(
    'active faces match opaque settled faces for every shape and orientation',
    () async {
      for (var type = 1; type <= 7; type++) {
        for (var rotation = 0; rotation < 4; rotation++) {
          final model = PuzzleModel(seed: 8);
          model.debugSetActive(
            type: type,
            column: 17,
            row: 22,
            rotation: rotation,
          );
          final game = ChandelierGame(model: model)
            ..onGameResize(Vector2(390, 844));
          final reference = await raster((canvas) {
            for (final cell in game.activeDrawCells) {
              game.paintBrick(canvas, cell.column, cell.row, type);
            }
          });
          final actual = await raster(
            game.paintActivePiece,
            file: rotation == 0 ? 'build/test/active-$type.png' : null,
          );
          var solidPixels = 0;
          for (var i = 0; i < reference.length; i += 4) {
            if (reference[i + 3] != 255) continue;
            solidPixels++;
            for (var channel = 0; channel < 4; channel++) {
              expect(
                actual[i + channel],
                reference[i + channel],
                reason:
                    'type $type rotation $rotation pixel ${i ~/ 4} channel $channel',
              );
            }
          }
          expect(solidPixels, greaterThan(100));
        }
      }
    },
  );
  test('first queue item is visibly larger than both successors', () {
    expect(
      ChandelierGame.previewBlockSize(0) / ChandelierGame.previewBlockSize(1),
      greaterThanOrEqualTo(1.5),
    );
    expect(
      ChandelierGame.previewBlockSize(1),
      greaterThan(ChandelierGame.previewBlockSize(2)),
    );
  });
  test(
    'night, dawn and day backdrop fixtures render without asset seams',
    () async {
      final data = await rootBundle.load('assets/images/night-landscape.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      Uint8List? previous;
      for (final seconds in [0.0, 180.0, 360.0, 540.0]) {
        final pixels = await raster(
          (canvas) => GardenBackdrop.paint(
            canvas,
            size: const Size(390, 844),
            image: image,
            seconds: seconds,
            yaw: 0,
          ),
          file: 'build/test/ambience-${seconds.toInt()}.png',
        );
        if (previous != null) expect(pixels, isNot(previous));
        for (var i = 3; i < pixels.length; i += 4) {
          expect(pixels[i], 255);
        }
        previous = pixels;
      }
      image.dispose();
      codec.dispose();
    },
  );
}
