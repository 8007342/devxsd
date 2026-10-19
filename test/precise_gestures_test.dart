import 'package:devxsd_gamejam/main.dart';
import 'package:devxsd_gamejam/game/chandelier_game.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PuzzleModel> start(WidgetTester tester) async {
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
  return (widget.game as ChandelierGame).model;
}

String cells(PuzzleModel model) =>
    model.activeCells.map((c) => '${c.column}:${c.row}').join(',');
void main() {
  testWidgets(
    'side taps rotate once and pulse the corresponding borderless icon',
    (tester) async {
      final model = await start(tester);
      model.debugSetActive(type: 3, column: 3, row: 25);
      final before = cells(model);
      await tester.tapAt(const Offset(80, 380));
      await tester.pump();
      expect(cells(model), isNot(before));
      final left = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('rotation--1')),
      );
      expect((left.decoration as BoxDecoration).border, isNull);
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(const ValueKey('rotation--1')),
                matching: find.byType(Icon),
              ),
            )
            .color,
        const Color(0xffa9f1d5),
      );
      await tester.tapAt(const Offset(300, 380));
      await tester.pump();
      expect(cells(model), before);
      expect(
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(const ValueKey('ascent-control')),
                    )
                    .decoration
                as BoxDecoration)
            .border,
        isNotNull,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(const ValueKey('rotation-1')),
                matching: find.byType(Icon),
              ),
            )
            .color,
        const Color(0xffefe0c4),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'upward swipes from each rotation icon launch the exact unrotated halo',
    (tester) async {
      final model = await start(tester);
      for (final direction in [-1, 1]) {
        model.reset();
        model.debugSetActive(type: 3, column: 4, row: 25);
        final halo = model.landingCells;
        final icon = find.byKey(ValueKey('rotation-$direction'));
        final origin = tester.getCenter(icon);
        final gesture = await tester.startGesture(origin);
        await gesture.moveBy(Offset(direction * 6.0, -18));
        await gesture.moveBy(Offset(direction * 12.0, -70));
        await gesture.up();
        for (final cell in halo) {
          expect(model.board[cell.row][cell.column], 3);
        }
        expect(
          model.board.expand((row) => row).where((cell) => cell != 0).length,
          4,
        );
        await tester.pump();
        final pulse = tester.widget<Icon>(
          find.descendant(of: icon, matching: find.byType(Icon)),
        );
        expect(pulse.color, const Color(0xffefe0c4));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'diagonal send and excursion returning to start never tap-rotate',
    (tester) async {
      final model = await start(tester);
      model.debugSetActive(type: 6, column: 5, row: 25);
      final halo = model.landingCells;
      final swipe = await tester.startGesture(const Offset(90, 420));
      await swipe.moveBy(const Offset(8, -16));
      await swipe.moveBy(const Offset(24, -70));
      await swipe.up();
      for (final cell in halo) {
        expect(model.board[cell.row][cell.column], 6);
      }
      model.debugSetActive(type: 3, column: 4, row: 25);
      final before = cells(model);
      final wiggle = await tester.startGesture(const Offset(90, 420));
      await wiggle.moveBy(const Offset(0, 30));
      await wiggle.moveBy(const Offset(0, -30));
      await wiggle.up();
      expect(cells(model), before);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'careful release and keyboard after rotation keep neighboring columns selectable',
    (tester) async {
      final model = await start(tester);
      model.debugSetActive(type: 2, column: 0, row: 25);
      final drag = await tester.startGesture(const Offset(160, 380));
      await drag.moveBy(const Offset(-18, 0));
      final selected = model.bestColumn;
      await drag.up();
      model.update(.2);
      expect(model.bestColumn, selected);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        var last = model.bestColumn;
        for (var j = 0; j < 18; j++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          expect(model.bestColumn, (last + 1) % 18);
          last = model.bestColumn;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        expect(model.bestColumn, (last - 1) % 18);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
