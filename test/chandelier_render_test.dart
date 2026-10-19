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
    test('modest zoom retains readable framing at $viewport', () {
      final model = PuzzleModel(seed: 42);
      final game = ChandelierGame(model: model);
      game.onGameResize(Vector2(viewport.width, viewport.height));
      for (final angle in [0.0, 4.5, 9.0, 17.9, -4.5]) {
        model.angle = angle;
        final bounds = game.projectedBoardBounds;
        expect(
          bounds.left,
          greaterThanOrEqualTo(-viewport.width * .06),
          reason: 'left rim at angle $angle',
        );
        expect(
          bounds.right,
          lessThanOrEqualTo(viewport.width * 1.06),
          reason: 'right rim at angle $angle',
        );
        expect(
          bounds.top,
          greaterThanOrEqualTo(viewport.height * .10),
          reason: 'crown below HUD/clip at angle $angle',
        );
        expect(
          bounds.bottom,
          lessThanOrEqualTo(viewport.height * .87),
          reason: 'bottom rim above controls at angle $angle',
        );
      }
    });
  }

  test(
    'crown and base keep the same shallow plane profile through rotation',
    () {
      final model = PuzzleModel(seed: 42);
      final game = ChandelierGame(model: model);
      game.onGameResize(Vector2(428, 926));
      double? firstHeight;
      for (final angle in [0.0, 2.5, 7.0, 11.5, 17.9]) {
        // Sample the slow camera at different times as well as board angles.
        for (var frame = 0; frame < 120; frame++) {
          game.update(1 / 60);
        }
        model.angle = angle;
        final crown = game.projectedRimBounds(-.8);
        final base = game.projectedRimBounds(41.8);
        expect(base.width, closeTo(crown.width, .001));
        expect(base.height, closeTo(crown.height, .001));
        expect(base.height / base.width, lessThan(.22));
        expect(base.center.dy, greaterThan(crown.center.dy));
        firstHeight ??= crown.height;
      }
      expect(
        game.projectedRimBounds(-.8).height,
        isNot(closeTo(firstHeight!, .01)),
      );
    },
  );

  for (final fixture in [
    (rings: 0, age: 0.0, vigor: 1.0, label: 'sprout'),
    (rings: 24, age: 0.0, vigor: 1.0, label: 'buds'),
    (rings: 24, age: 3.0, vigor: 1.0, label: 'unfolding'),
    (rings: 24, age: 10.0, vigor: 1.0, label: 'mature'),
    (rings: 24, age: 10.0, vigor: 1.54, label: 'multi-clear'),
    (rings: 120, age: 10.0, vigor: 1.18, label: 'late-growth'),
  ]) {
    final growth = fixture.rings;
    testWidgets('botanical assets render ${fixture.label}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = PuzzleModel(seed: 42)..rings = growth;
      if (growth > 0) {
        model.leaves.addAll(
          List.generate(
            24,
            (i) => PlantLeaf(
              node: growth - 23 + i,
              bornAt: -fixture.age,
              vigor: fixture.vigor,
              variation: ((i * 13) % 19) / 19,
              azimuth: ((i * 7) % 11) / 11,
            ),
          ),
        );
      }
      for (var row = 0; row < (growth == 0 ? 0 : 18); row++) {
        model.board[row][0] = row % 7 + 1;
        model.board[row][9] = (row + 3) % 7 + 1;
        if (row.isEven) model.board[row][2] = 4;
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
      expect(game.projectedBoardBounds.top, greaterThanOrEqualTo(844 * .10));
      expect(game.projectedBoardBounds.bottom, lessThanOrEqualTo(844 * .87));
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
