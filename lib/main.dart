import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: GameJam()));
}

class GameJam extends FlameGame {
  final TextComponent greeting = TextComponent(
    text: 'DEVxSD GameJam!',
    anchor: Anchor.center,
    textRenderer: TextPaint(
      style: const TextStyle(color: Colors.white, fontSize: 28),
    ),
  );

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await add(greeting);
    greeting.position = size / 2;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    greeting.position = size / 2;
  }
}
