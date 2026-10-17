import 'package:devxsd_gamejam/main.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('greeting is the only game component and stays centered', (
    tester,
  ) async {
    final game = GameJam();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();
    await tester.runAsync(() => game.loaded);
    await tester.pump();

    expect(game.greeting.text, 'DEVxSD GameJam!');
    expect(game.greeting.parent, game);
    expect(game.children.whereType<TextComponent>().toList(), [game.greeting]);
    expect(game.greeting.position, game.size / 2);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(game.greeting.position, game.size / 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
