import 'package:flutter/services.dart';
import 'package:devxsd_gamejam/game/chandelier_game.dart';
import 'package:flame/game.dart';
import 'package:devxsd_gamejam/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('phone can start, pause and resume the combined game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChandelierApp());
    expect(find.text('Chandelier'), findsOneWidget);
    await tester.tap(find.text('Grow a garden'));
    await tester.pump();
    expect(find.text('CHANDELIER'), findsOneWidget);
    expect(find.bySemanticsLabel('Rotate clockwise'), findsOneWidget);
    expect(find.bySemanticsLabel('Hold to accelerate'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('A little breathing room'), findsOneWidget);
    await tester.tap(find.text('Keep growing'));
    await tester.pump();
    expect(find.text('A little breathing room'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('combined game can return home', (tester) async {
    await tester.pumpWidget(const ChandelierApp());
    await tester.tap(find.text('Grow a garden'));
    await tester.pump();
    expect(find.text('CHANDELIER'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    await tester.tap(find.text('Back to the conservatory'));
    await tester.pump();
    expect(find.text('Grow a garden'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'drag follows finger, ignores a second pointer and cancels on pause',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChandelierApp());
      await tester.tap(find.text('Grow a garden'));
      await tester.pump();
      final widget = tester.widget<GameWidget>(
        find.byWidgetPredicate((w) => w is GameWidget),
      );
      final model = (widget.game as ChandelierGame).model;
      final drag = await tester.startGesture(
        const Offset(140, 350),
        pointer: 7,
      );
      await drag.moveBy(const Offset(60, 0));
      expect(model.dragging, isTrue);
      expect(
        model.angle,
        lessThan(0),
      ); // Renderer subtracts yaw, so negative turns right.
      final heldAngle = model.angle;
      model.update(0.1);
      expect(model.angle, heldAngle); // No snap-back under an active finger.
      final other = await tester.startGesture(
        const Offset(230, 400),
        pointer: 8,
      );
      await other.moveBy(const Offset(0, -100));
      await other.up();
      expect(model.dragging, isTrue);
      expect(model.angle, heldAngle);
      expect(model.board.expand((r) => r).every((cell) => cell == 0), isTrue);
      await tester.tap(find.byTooltip('Pause'), pointer: 9);
      await tester.pump();
      expect(model.dragging, isFalse);
      expect(model.spinVelocity, 0);
      await drag.up();
      await tester.tap(find.text('Keep growing'));
      await tester.pump();
      expect(model.dragging, isFalse);
      final resumed = model.angle;
      model.update(0.1);
      expect(
        (model.angle - model.activeCenterColumn).abs(),
        lessThan((resumed - resumed.round()).abs()),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'FireUp accelerates only while held and cancellation releases it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChandelierApp());
      await tester.tap(find.text('Grow a garden'));
      await tester.pump();
      final widget = tester.widget<GameWidget>(
        find.byWidgetPredicate((w) => w is GameWidget),
      );
      final model = (widget.game as ChandelierGame).model;
      final fire = find.bySemanticsLabel('Hold to accelerate');
      final held = await tester.startGesture(
        tester.getCenter(fire),
        pointer: 11,
      );
      expect(model.softDrop, isTrue);
      await held.up();
      expect(model.softDrop, isFalse);
      final cancelled = await tester.startGesture(
        tester.getCenter(fire),
        pointer: 12,
      );
      expect(model.softDrop, isTrue);
      await cancelled.cancel();
      expect(model.softDrop, isFalse);
      expect(model.board.expand((r) => r).every((cell) => cell == 0), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('keyboard turns cylinder, rotates pieces and launches to halo', (
    tester,
  ) async {
    await tester.pumpWidget(const ChandelierApp());
    await tester.tap(find.text('Grow a garden'));
    await tester.pump();
    final widget = tester.widget<GameWidget>(
      find.byWidgetPredicate((w) => w is GameWidget),
    );
    final model = (widget.game as ChandelierGame).model;
    model.debugSetActive(type: 3, column: 0, row: 30);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(model.angle, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(model.angle, 1);
    String cells() =>
        model.activeCells.map((c) => '${c.column}:${c.row}').join(',');
    final original = cells();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(cells(), isNot(original));
    expect(model.softDrop, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(cells(), original);
    expect(model.softDrop, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    expect(cells(), original);
    final halo = model.landingCells;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    for (final cell in halo) {
      expect(model.board[cell.row][cell.column], 3);
    }
    expect(model.contactTime, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
