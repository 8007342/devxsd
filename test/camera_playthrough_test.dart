import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:devxsd_gamejam/game/chandelier_game.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void expectVisible(Rect bounds, Size viewport, String stage) {
  expect(bounds.left, greaterThanOrEqualTo(0), reason: '$stage left');
  expect(
    bounds.right,
    lessThanOrEqualTo(viewport.width),
    reason: '$stage right',
  );
  expect(
    bounds.top,
    greaterThanOrEqualTo(math.max(128, viewport.height * .15)),
    reason: '$stage below HUD',
  );
  expect(
    bounds.bottom,
    lessThanOrEqualTo(viewport.height * 1.03),
    reason: '$stage only thin bottom cropping',
  );
}

void expectBaseInView(Rect bounds, Size viewport, String stage) {
  expect(
    bounds.width.isFinite && bounds.height.isFinite,
    isTrue,
    reason: '$stage projected base remains valid outside the close-up',
  );
}

void expectLocalCells(ChandelierGame game, PuzzleModel model, String stage) {
  final minimum = game.size.x >= 500 ? 28.0 : 35.0;
  for (final cell in model.activeCells) {
    final face = game.projectedBrickFace(
      cell.column.toDouble(),
      cell.row - model.riseProgress,
    );
    final width = (face[1] - face[0]).distance;
    final height = (face[3] - face[0]).distance;
    expect(
      width,
      greaterThanOrEqualTo(minimum),
      reason: '$stage readable active width',
    );
    expect(
      height,
      greaterThanOrEqualTo(minimum),
      reason: '$stage readable active height',
    );
    expect(
      width / height,
      inInclusiveRange(.7, 1.4),
      reason: '$stage near-square active cell',
    );
  }
}

void main() {
  for (final viewport in [
    const Size(390, 844),
    const Size(428, 926),
    const Size(520, 720),
  ]) {
    test(
      'camera follows real natural ascent and immediately restores spawn at $viewport',
      () {
        final model = PuzzleModel(seed: 1);
        final game = ChandelierGame(model: model);
        game.onGameResize(Vector2(viewport.width, viewport.height));
        game.resetView();
        game.update(0);
        expectVisible(game.projectedActiveBounds, viewport, 'initial spawn');
        expect(
          game.projectedActiveBounds.bottom / viewport.height,
          closeTo(1.015, .006),
        );
        expect(
          game.projectedActiveBounds.top,
          lessThan(viewport.height * .95),
          reason: 'cropped active silhouette remains recognizable',
        );
        expect(
          game.projectedRimBounds(-.8).top,
          greaterThanOrEqualTo(math.max(128, viewport.height * .15)),
        );
        final base = game.projectedRimBounds(41.8);
        final crown = game.projectedRimBounds(-.8);

        expect(
          base.width,
          greaterThan(crown.width),
          reason: 'near base larger than distant crown',
        );
        final firstPiece = model.pieceSerial;
        var frames = 0;
        while (model.pieceSerial == firstPiece && frames < 1000) {
          game.update(.05);
          expectVisible(
            game.projectedActiveBounds,
            viewport,
            'natural frame $frames',
          );
          expectVisible(
            game.projectedLandingBounds,
            viewport,
            'landing frame $frames',
          );
          if (frames % 20 == 0) {
            expectLocalCells(game, model, 'natural frame $frames');
          }
          frames++;
        }
        expect(
          frames,
          lessThan(1000),
          reason: 'piece actually reaches and locks against crown',
        );
        expect(
          frames,
          greaterThan(700),
          reason: 'test exercises full natural ascent',
        );
        expect(
          model.activeCells.map((cell) => cell.row).reduce(math.max),
          greaterThanOrEqualTo(39),
        );
        expectVisible(
          game.projectedActiveBounds,
          viewport,
          'new natural spawn',
        );
        expectBaseInView(
          game.projectedRimBounds(41.8),
          viewport,
          'base after natural lock',
        );
        for (var launch = 0; launch < 7; launch++) {
          model.hardDrop();
          game.update(0);
          expectVisible(
            game.projectedActiveBounds,
            viewport,
            'new hard launch spawn $launch',
          );
          expectBaseInView(
            game.projectedRimBounds(41.8),
            viewport,
            'new hard launch base $launch',
          );
          expectLocalCells(game, model, 'new hard launch $launch');
        }
        expectBaseInView(base, viewport, 'initial base');
        model.reset();
        game.resetView();
        game.update(0);
        expectVisible(game.projectedActiveBounds, viewport, 'reset spawn');
      },
    );
  }

  test(
    'accelerated ascent remains framed while spinning toward a tall stack',
    () {
      const viewport = Size(390, 844);
      final model = PuzzleModel(seed: 3)..rings = 12;
      for (var row = 0; row < 25; row++) {
        for (var column = 0; column < 18; column += 3) {
          model.debugSetSettled(
            row: row,
            column: column,
            type: column % 7 + 1,
            age: 22,
          );
        }
      }
      final game = ChandelierGame(model: model);
      game.onGameResize(Vector2(viewport.width, viewport.height));
      game.resetView();
      model.softDrop = true;
      model.beginDrag();
      for (var frame = 0; frame < 20; frame++) {
        model.dragColumns(.15);
        game.update(.05);
        expectVisible(
          game.projectedActiveBounds,
          viewport,
          'spinning soft ascent $frame',
        );
        expectVisible(
          game.projectedLandingBounds,
          viewport,
          'spinning destination $frame',
        );
      }
      model.releaseSpin(8);
      for (var frame = 0; frame < 10; frame++) {
        game.update(.05);
      }
      expectVisible(game.projectedActiveBounds, viewport, 'settled spin');
      model.hardDrop();
      game.update(0);
      expectVisible(
        game.projectedActiveBounds,
        viewport,
        'tall stack new spawn',
      );
    },
  );

  testWidgets(
    'capture actual spawn, accelerated ascent, contact and next spawn',
    (tester) async {
      const viewport = Size(390, 844);
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = PuzzleModel(seed: 2);
      final game = ChandelierGame(model: model);
      await tester.runAsync(
        () => game.images.loadAll(['monstera-leaf.png', 'night-landscape.png']),
      );
      final key = GlobalKey();
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
      await tester.runAsync(() => game.loaded);
      game.pauseEngine();
      List<int>? previousPng;
      Future<void> capture(String stage) async {
        // Manual simulation bypasses Flame's ticker; invalidate nested repaint
        // boundaries so the artifact represents this frame, not the last tick.
        void invalidate(RenderObject object) {
          object.markNeedsPaint();
          object.visitChildren(invalidate);
        }

        invalidate(key.currentContext!.findRenderObject()!);
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final png = bytes!.buffer.asUint8List();
          if (previousPng != null) {
            expect(
              png,
              isNot(orderedEquals(previousPng!)),
              reason: '$stage must be a fresh rendered frame',
            );
          }
          previousPng = png.toList();
          final file = File('build/test/camera-$stage.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png);
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      game.resetView();
      game.update(0);
      await capture('spawn');
      final initialRow = model.activeCells
          .map((cell) => cell.row)
          .reduce(math.min);
      final initialFocus = game.cameraFocusRow;
      final initialSerial = model.pieceSerial;
      model.softDrop = true;
      for (var frame = 0; frame < 32; frame++) {
        game.update(.05);
      }
      expect(
        model.activeCells.map((cell) => cell.row).reduce(math.min),
        lessThan(initialRow - 10),
      );
      expect(game.cameraFocusRow, lessThan(initialFocus - 10));
      await capture('mid-ascent');
      model.softDrop = false;
      var contactFrames = 0;
      while (model.contactTime == 0 &&
          model.pieceSerial == initialSerial &&
          contactFrames < 1000) {
        game.update(.05);
        contactFrames++;
      }
      expect(model.pieceSerial, initialSerial);
      expect(model.contactTime, greaterThan(0));
      expect(game.cameraFocusRow, lessThan(7));
      await capture('contact');
      model.hardDrop();
      game.update(0);
      expect(model.pieceSerial, greaterThan(initialSerial));
      expect(game.cameraFocusRow, greaterThan(39));
      await capture('next-spawn');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
