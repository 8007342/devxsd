import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/leaderboard_repository.dart';
import 'game/chandelier_game.dart';
import 'game/puzzle_model.dart';

void main() => runApp(const ChandelierApp());

const _cream = Color(0xffefe0c4);
const _mint = Color(0xffa9f1d5);
const _ink = Color(0xff091c21);

class ChandelierApp extends StatelessWidget {
  const ChandelierApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Chandelier · a growing puzzle',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _ink,
      fontFamily: 'NotoSans',
      colorScheme: const ColorScheme.dark(
        primary: _mint,
        surface: Color(0xff123036),
        onSurface: _cream,
      ),
    ),
    home: const GardenScreen(),
  );
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final PuzzleModel model = PuzzleModel();
  final LeaderboardRepository repository = LeaderboardRepository();
  final FocusNode focus = FocusNode();
  final TextEditingController initials = TextEditingController(text: 'AAA');
  late final ChandelierGame game = ChandelierGame(model: model);
  Timer? pulse;
  int runId = 0;
  bool started = false;
  bool paused = false;
  bool results = false;
  bool showBoard = false;
  bool saving = false;
  bool submitted = false;
  String? boardError;
  LeaderboardTable? table;
  GameMode boardMode = GameMode.timed;
  int? activePointer;
  Offset? down;
  Offset? last;
  DateTime? lastDragTime;
  double dragVelocity = 0;
  bool dragged = false;
  double playWidth = 400;

  @override
  void initState() {
    super.initState();
    pulse = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (started && model.finished && !results) {
        results = true;
        _clearPointer();
        model.releaseSpin(0);
        model.softDrop = false;
        game.pauseEngine();
        _loadBoard(model.mode);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    pulse?.cancel();
    focus.dispose();
    initials.dispose();
    game.pauseEngine();
    super.dispose();
  }

  void _start(GameMode mode) {
    _clearPointer();
    runId++;
    model.reset(mode: mode);
    game.resetView();
    game.resumeEngine();
    setState(() {
      started = true;
      paused = false;
      results = false;
      showBoard = false;
      submitted = false;
      saving = false;
      boardError = null;
    });
    focus.requestFocus();
  }

  void _pause() {
    if (!started || results || showBoard) return;
    _clearPointer();
    model.releaseSpin(0);
    setState(() => paused = !paused);
    model.softDrop = false;
    if (paused) {
      game.pauseEngine();
    } else {
      game.resumeEngine();
      focus.requestFocus();
    }
  }

  bool get canPlay => started && !paused && !results && !showBoard;

  Future<void> _loadBoard(GameMode mode) async {
    setState(() {
      boardMode = mode;
      table = null;
      boardError = null;
    });
    try {
      final loaded = await repository.fetch(mode);
      if (mounted && boardMode == mode) setState(() => table = loaded);
    } catch (_) {
      if (mounted) setState(() => boardError = 'Scores could not be loaded.');
    }
  }

  Future<void> _submit() async {
    final name = initials.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(name) || saving || submitted) return;
    final submittedRun = runId;
    setState(() => saving = true);
    try {
      final loaded = await repository.submit(
        model.mode,
        name,
        model.elapsed,
        model.rings,
        model.plantHeight.toDouble(),
      );
      if (mounted && submittedRun == runId) {
        setState(() {
          table = loaded;
          submitted = true;
          saving = false;
        });
      }
    } catch (_) {
      if (mounted && submittedRun == runId) {
        setState(() {
          saving = false;
          boardError = 'Could not save. Please try again.';
        });
      }
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.keyP && event is KeyDownEvent) {
      _pause();
      return KeyEventResult.handled;
    }
    if (!canPlay) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        model.dragColumns(-1);
        model.releaseSpin(0);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        model.dragColumns(1);
        model.releaseSpin(0);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        model.rotatePiece(-1);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        model.rotatePiece(1);
      } else if (key == LogicalKeyboardKey.space) {
        model.hardDrop();
      } else {
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.handled;
  }

  void _clearPointer() {
    activePointer = null;
    down = last = null;
    dragged = false;
    dragVelocity = 0;
  }

  void _pointerDown(PointerDownEvent event) {
    if (!canPlay || activePointer != null) return;
    activePointer = event.pointer;
    down = last = event.localPosition;
    dragged = false;
    dragVelocity = 0;
    lastDragTime = DateTime.now();
    focus.requestFocus();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!canPlay || down == null || event.pointer != activePointer) return;
    final offset = event.localPosition - down!;
    if (offset.dx.abs() > 10 && offset.dx.abs() > offset.dy.abs() * 1.15) {
      if (!dragged) model.beginDrag();
      dragged = true;
    }
    if (dragged) {
      final now = DateTime.now();
      final seconds = (now.difference(lastDragTime!).inMicroseconds / 1e6)
          .clamp(0.008, 0.1);
      final columns = -(event.localPosition.dx - last!.dx) / playWidth * 12;
      model.dragColumns(columns);
      dragVelocity = (dragVelocity * 0.35 + columns / seconds * 0.65).clamp(
        -32,
        32,
      );
      lastDragTime = now;
    }
    last = event.localPosition;
  }

  void _pointerUp(PointerUpEvent event) {
    if (!canPlay || down == null || event.pointer != activePointer) return;
    final delta = event.localPosition - down!;
    if (dragged) {
      final stale =
          DateTime.now().difference(lastDragTime!).inMilliseconds > 100;
      model.releaseSpin(stale ? 0 : dragVelocity);
    } else if (delta.dy < -35 && delta.dy.abs() > delta.dx.abs()) {
      model.hardDrop();
    } else if (delta.distance < 14) {
      model.rotatePiece(event.localPosition.dx < playWidth / 2 ? -1 : 1);
    }
    _clearPointer();
  }

  String _clock(double seconds) {
    final total = (seconds * 10).floor();
    return '${(total ~/ 600).toString().padLeft(2, '0')}:${(total ~/ 10 % 60).toString().padLeft(2, '0')}.${total % 10}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Focus(
      focusNode: focus,
      onKeyEvent: _key,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xff193b3c), _ink],
            radius: 0.9,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  playWidth = constraints.maxWidth;
                  return ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Listener(
                            onPointerDown: _pointerDown,
                            onPointerMove: _pointerMove,
                            onPointerUp: _pointerUp,
                            onPointerCancel: (event) {
                              if (event.pointer == activePointer) {
                                _clearPointer();
                                model.releaseSpin(0);
                              }
                            },
                            child: GameWidget(game: game),
                          ),
                        ),
                        if (started && !showBoard) _hud(),
                        if (canPlay) _controls(constraints.maxHeight * 0.20),
                        if (!started && !showBoard) _welcome(),
                        if (paused && !showBoard) _pauseCard(),
                        if (results && !showBoard) _resultsCard(),
                        if (showBoard) _leaderboardCard(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _hud() => Positioned(
    top: 14,
    left: 22,
    right: 16,
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.spa_outlined, size: 18, color: _mint),
            const SizedBox(width: 8),
            Text(
              model.mode == GameMode.timed
                  ? '30 RING SPRINT'
                  : 'ENDLESS GARDEN',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: _mint,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: paused ? 'Resume' : 'Pause',
              onPressed: _pause,
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: _cream,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _metric(
              'RINGS',
              '${model.rings}${model.mode == GameMode.timed ? ' / 30' : ''}',
            ),
            _metric('TIME', _clock(model.elapsed)),
            _metric('GROWTH', '${model.plantHeight.toStringAsFixed(0)} cm'),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: model.mode == GameMode.timed
                ? (model.rings / 30).clamp(0, 1)
                : model.occupancy,
            minHeight: 2,
            backgroundColor: _cream.withValues(alpha: 0.08),
            color: _mint.withValues(alpha: 0.65),
          ),
        ),
      ],
    ),
  );

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 8,
          letterSpacing: 2,
          color: _cream.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 19,
          fontFeatures: [FontFeature.tabularFigures()],
          color: _cream,
        ),
      ),
    ],
  );

  Widget _controls(double height) => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _ink.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _control(
                Icons.rotate_left_rounded,
                'Rotate counterclockwise',
                () => model.rotatePiece(-1),
              ),
              _control(
                Icons.keyboard_double_arrow_up_rounded,
                'Hold to accelerate',
                null,
                hold: true,
              ),
              _control(
                Icons.rotate_right_rounded,
                'Rotate clockwise',
                () => model.rotatePiece(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${model.speed.toStringAsFixed(2)}×  ·  SWIPE TO TURN / SWIPE UP TO SEND',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 1,
              color: _cream.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _control(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool hold = false,
  }) => Semantics(
    label: label,
    button: true,
    child: Listener(
      onPointerDown: hold ? (_) => setState(() => model.softDrop = true) : null,
      onPointerUp: hold ? (_) => setState(() => model.softDrop = false) : null,
      onPointerCancel: hold
          ? (_) => setState(() => model.softDrop = false)
          : null,
      child: GestureDetector(
        onTap: action,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: hold ? 76 : 62,
          height: hold ? 76 : 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (hold && model.softDrop ? _mint : _cream).withValues(
              alpha: hold && model.softDrop ? 0.18 : 0.06,
            ),
            border: Border.all(color: _cream.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: hold ? 38 : 29, color: _cream),
        ),
      ),
    ),
  );

  Widget _sheet(Widget child) => Positioned.fill(
    child: ColoredBox(
      color: _ink.withValues(alpha: 0.60),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(27),
            decoration: BoxDecoration(
              color: const Color(0xff10292e).withValues(alpha: 0.96),
              border: Border.all(color: _cream.withValues(alpha: 0.16)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );

  Widget _welcome() => _sheet(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.spa_outlined, color: _mint, size: 34),
        const SizedBox(height: 25),
        const Text(
          'A GROWING PUZZLE',
          style: TextStyle(fontSize: 9, letterSpacing: 3, color: _mint),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chandelier',
          style: TextStyle(
            fontSize: 37,
            height: 1.2,
            fontWeight: FontWeight.w300,
            color: _cream,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Send pieces toward the light.\nClear a ring. Make room to grow.',
          style: TextStyle(
            fontSize: 13,
            height: 1.8,
            color: _cream.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 27),
        _button(
          '30-ring sprint',
          () => _start(GameMode.timed),
          primary: true,
          icon: Icons.north_rounded,
        ),
        const SizedBox(height: 10),
        _button(
          'Endless garden',
          () => _start(GameMode.unlimited),
          icon: Icons.all_inclusive,
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xff2c484a)),
        const SizedBox(height: 12),
        Text(
          'Drag sideways to turn the chandelier.\nTap either side to rotate your piece.\nSwipe up to send it straight to its halo.',
          style: TextStyle(
            fontSize: 11,
            height: 1.8,
            color: _cream.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => showBoard = true);
            game.pauseEngine();
            _loadBoard(GameMode.timed);
          },
          child: const Text(
            'THE TOP TEN',
            style: TextStyle(fontSize: 9, letterSpacing: 2, color: _mint),
          ),
        ),
      ],
    ),
  );

  Widget _pauseCard() => _sheet(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_rounded, size: 32, color: _mint),
        const SizedBox(height: 18),
        const Text('A little breathing room', style: TextStyle(fontSize: 21)),
        const SizedBox(height: 22),
        _button('Keep growing', _pause, primary: true),
        const SizedBox(height: 10),
        _button('New garden', () => _start(model.mode)),
        TextButton(
          onPressed: () => setState(() {
            started = false;
            paused = false;
          }),
          child: const Text('Back to the conservatory'),
        ),
      ],
    ),
  );

  Widget _resultsCard() {
    final eligible = model.mode == GameMode.unlimited || model.won;
    return _sheet(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.won ? 'THIRTY RINGS OF LIGHT' : 'THE GARDEN RESTS',
            style: const TextStyle(fontSize: 9, letterSpacing: 2, color: _mint),
          ),
          const SizedBox(height: 12),
          Text(
            model.won ? 'Room to flourish.' : 'A little more room next time.',
            style: const TextStyle(fontSize: 25, height: 1.3),
          ),
          const SizedBox(height: 20),
          Text(
            '${model.rings} rings  ·  ${_clock(model.elapsed)}  ·  ${model.plantHeight.toStringAsFixed(0)} cm',
            style: const TextStyle(fontSize: 12, color: _mint),
          ),
          const SizedBox(height: 20),
          if (eligible && !submitted) ...[
            const Text(
              'LEAVE THREE LETTERS',
              style: TextStyle(fontSize: 9, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: initials,
              maxLength: 3,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
              ],
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
                color: _cream,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'AAA',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _button(
              saving ? 'Saving…' : 'Save to the top ten',
              saving ? null : _submit,
              primary: true,
            ),
          ],
          if (submitted)
            const Text(
              'Your growth is recorded.',
              style: TextStyle(color: _mint),
            ),
          if (boardError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(boardError!, style: const TextStyle(fontSize: 11)),
            ),
          const SizedBox(height: 16),
          _button('Grow again', () => _start(model.mode)),
          TextButton(
            onPressed: () {
              setState(() => showBoard = true);
              _loadBoard(model.mode);
            },
            child: const Text('View the top ten'),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardCard() => _sheet(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE TOP TEN',
          style: TextStyle(fontSize: 9, letterSpacing: 3, color: _mint),
        ),
        const SizedBox(height: 12),
        const Text('Growing legends', style: TextStyle(fontSize: 27)),
        const SizedBox(height: 18),
        Row(
          children: [
            ChoiceChip(
              label: const Text('30 rings'),
              selected: boardMode == GameMode.timed,
              onSelected: (_) => _loadBoard(GameMode.timed),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Endless'),
              selected: boardMode == GameMode.unlimited,
              onSelected: (_) => _loadBoard(GameMode.unlimited),
            ),
          ],
        ),
        const SizedBox(height: 17),
        if (table == null && boardError == null)
          const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        if (boardError != null) Text(boardError!),
        if (table != null) ...[
          Text(
            table!.shared ? 'SHARED GARDEN' : 'THIS DEVICE · LOCAL SCORES',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 1.5,
              color: _cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          if (table!.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'The first seed is yours to plant.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          for (var i = 0; i < table!.entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 11,
                        color: _cream.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Text(
                    table!.entries[i].name,
                    style: const TextStyle(fontSize: 14, letterSpacing: 3),
                  ),
                  const Spacer(),
                  Text(
                    boardMode == GameMode.timed
                        ? _clock(table!.entries[i].seconds)
                        : '${table!.entries[i].height.toStringAsFixed(0)} cm',
                    style: const TextStyle(fontSize: 13, color: _mint),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 20),
        _button('Back', () {
          setState(() => showBoard = false);
          if (started && !paused && !results) game.resumeEngine();
        }),
      ],
    ),
  );

  Widget _button(
    String text,
    VoidCallback? action, {
    bool primary = false,
    IconData? icon,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        backgroundColor: primary ? _mint : _cream.withValues(alpha: 0.06),
        foregroundColor: primary ? _ink : _cream,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: const TextStyle(fontSize: 12, letterSpacing: 0.5)),
          if (icon != null) ...[
            const SizedBox(width: 12),
            Icon(icon, size: 16),
          ],
        ],
      ),
    ),
  );
}
