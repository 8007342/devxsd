import 'dart:io';
import 'dart:ui' as ui;

import 'package:devxsd_gamejam/game/chandelier_game.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final viewport in [
    const Size(390, 844),
    const Size(428, 926),
    const Size(520, 720),
  ]) {
    test(
      'upward camera keeps the active and landing area visible at $viewport',
      () {
        for (final stack in [0, 12, 28]) {
          final model = PuzzleModel(seed: 42);
          if (stack > 0) model.board[stack - 1].fillRange(0, 18, 1);
          final game = ChandelierGame(model: model);
          game.onGameResize(Vector2(viewport.width, viewport.height));
          game.update(1 / 60);
          expect(
            game.projectedLandingBounds.top,
            greaterThanOrEqualTo(viewport.height * .14),
          );
          expect(
            game.projectedLandingBounds.bottom,
            lessThanOrEqualTo(viewport.height * 1.03),
          );
          for (var frame = 0; frame < 180; frame++) {
            game.update(1 / 60);
          }
          for (final angle in [0.0, 4.5, 9.0, 17.9, -4.5]) {
            model.angle = angle;
            final bounds = game.projectedLandingBounds;
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(viewport.width));
            expect(bounds.top, greaterThanOrEqualTo(viewport.height * .14));
            expect(bounds.bottom, lessThanOrEqualTo(viewport.height * 1.03));
            expect(
              game.projectedActiveBounds.top,
              greaterThanOrEqualTo(viewport.height * .14),
            );
            expect(
              game.projectedActiveBounds.bottom,
              lessThanOrEqualTo(viewport.height * 1.03),
            );
          }
        }
      },
    );
  }

  for (final viewport in [
    const Size(390, 844),
    const Size(428, 926),
    const Size(520, 720),
  ]) {
    test('front cells are square at $viewport across rotation', () {
      final model = PuzzleModel(seed: 42);
      final game = ChandelierGame(model: model);
      game.onGameResize(Vector2(viewport.width, viewport.height));
      for (final angle in [0.0, 4.5, 9.0, 17.9]) {
        model.angle = angle;
        final row =
            model.activeCells.fold<double>(0, (sum, c) => sum + c.row) /
            model.activeCells.length;
        final face = game.projectedBrickFace(angle, row);
        final width =
            ((face[1] - face[0]).distance + (face[2] - face[3]).distance) / 2;
        final height =
            ((face[3] - face[0]).distance + (face[2] - face[1]).distance) / 2;
        expect(width / height, inInclusiveRange(.75, 1.33));
      }
    });
  }

  test('upward perspective makes the nearby base larger than the crown', () {
    final model = PuzzleModel(seed: 42);
    final game = ChandelierGame(model: model);
    game.onGameResize(Vector2(428, 926));
    game.resetView();
    for (final angle in [0.0, 2.5, 7.0, 11.5, 17.9]) {
      model.angle = angle;
      final crown = game.projectedRimBounds(-.8);
      final base = game.projectedRimBounds(41.8);
      expect(base.width, greaterThan(crown.width * 2));
      expect(base.center.dy, greaterThan(crown.center.dy));
      expect(base.width.isFinite && base.height.isFinite, isTrue);
      final nearFace = game.projectedBrickFace(angle, 39);
      final farFace = game.projectedBrickFace(angle, 1);
      expect(
        (nearFace[1] - nearFace[0]).distance,
        greaterThan((farFace[1] - farFace[0]).distance * 2),
      );
    }
  });

  for (final fixture in [
    (rings: 0, age: 0.0, label: 'sprout'),
    (rings: 24, age: 0.0, label: 'growth'),
    (rings: 24, age: 22.0, label: 'growth-aged'),
  ]) {
    final growth = fixture.rings;
    testWidgets('botanical assets and cylinder render ${fixture.label}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = PuzzleModel(seed: 42)
        ..rings = growth
        ..elapsed = fixture.age;
      for (var row = 0; row < (growth == 0 ? 0 : 18); row++) {
        model.debugSetSettled(
          row: row,
          column: 0,
          type: row % 7 + 1,
          age: fixture.age,
        );
        model.debugSetSettled(
          row: row,
          column: 9,
          type: (row + 3) % 7 + 1,
          age: fixture.age,
        );
        if (row.isEven) {
          model.debugSetSettled(row: row, column: 2, type: 4, age: fixture.age);
        }
      }
      expect(model.stackDepth, growth == 0 ? 0 : 18);
      final game = ChandelierGame(model: model);
      final key = GlobalKey();
      await tester.runAsync(
        () => game.images.loadAll(['monstera-leaf.png', 'night-landscape.png']),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: GameWidget(game: game),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => game.loaded.timeout(const Duration(seconds: 15)),
      );
      // onLoad deliberately has a procedural fallback; checking the cache proves
      // this fixture actually exercises decoding of the bundled generated art.
      for (final asset in ['monstera-leaf.png', 'night-landscape.png']) {
        expect(
          game.images.containsKey(asset),
          isTrue,
          reason: '$asset decoded',
        );
        final image = game.images.fromCache(asset);
        expect(image.width, greaterThan(0));
        expect(image.height, greaterThan(0));
      }
      for (var frame = 0; frame < 120; frame++) {
        game.update(1 / 60);
      }
      expect(game.projectedLandingBounds.top, greaterThanOrEqualTo(844 * .14));
      expect(game.projectedLandingBounds.bottom, lessThanOrEqualTo(844 * 1.03));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        expect(image.width, 390);
        expect(image.height, 844);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes, isNotNull);
        final destination = File('build/test/${fixture.label}.png');
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
}
