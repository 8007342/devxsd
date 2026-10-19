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

enum _GestureIntent { pending, turn, send }

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
  static const boardMode = GameMode.unlimited;
  int? activePointer;
  Offset? down;
  Offset? last;
  DateTime? lastDragTime;
  double dragVelocity = 0;
  _GestureIntent intent = _GestureIntent.pending;
  double maximumTravel = 0;
  int? holdPointer;
  bool ascentGesture = false;
  DateTime? touchStarted;
  int rotationFlash = 0;
  Timer? flashTimer;
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
        _loadBoard();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    pulse?.cancel();
    flashTimer?.cancel();
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

  Future<void> _loadBoard() async {
    const mode = boardMode;
    setState(() {
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
      final loaded = await repository.submitRun(
        boardMode,
        name,
        model.elapsed,
        model.rings,
        model.plantHeight.toDouble(),
        model.thirtyRingTime,
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
        model.shiftColumn(-1);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        model.shiftColumn(1);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _rotate(-1);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _rotate(1);
      } else if (key == LogicalKeyboardKey.space) {
        model.hardDrop();
      } else {
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.handled;
  }

  void _rotate(int direction) {
    if (!canPlay) return;
    model.rotatePiece(direction);
    flashTimer?.cancel();
    setState(() => rotationFlash = direction);
    flashTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => rotationFlash = 0);
    });
  }

  void _clearPointer() {
    activePointer = null;
    down = last = null;
    intent = _GestureIntent.pending;
    maximumTravel = 0;
    dragVelocity = 0;
    holdPointer = null;
    ascentGesture = false;
    model.softDrop = false;
  }

  void _pointerDown(PointerDownEvent event) {
    if (!canPlay || activePointer != null) return;
    activePointer = event.pointer;
    down = last = event.localPosition;
    ascentGesture = holdPointer == event.pointer;
    intent = _GestureIntent.pending;
    maximumTravel = 0;
    dragVelocity = 0;
    touchStarted = lastDragTime = DateTime.now();
    // Touching the board stops any old coast before a new precise gesture.
    model.beginDrag();
    focus.requestFocus();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!canPlay || down == null || event.pointer != activePointer) return;
    final offset = event.localPosition - down!;
    maximumTravel = maximumTravel > offset.distance
        ? maximumTravel
        : offset.distance;
    if (maximumTravel > 12) model.softDrop = false;
    if (intent == _GestureIntent.pending) {
      if (offset.dy < -12 && -offset.dy > offset.dx.abs() * 1.1) {
        intent = _GestureIntent.send;
      } else if (offset.dx.abs() > 12 &&
          offset.dx.abs() > offset.dy.abs() * 1.35) {
        intent = _GestureIntent.turn;
      }
    }
    if (intent == _GestureIntent.turn) {
      // A deliberate upward finish may send after a turn, never tap-rotate.
      if (offset.dy < -35 && -offset.dy > offset.dx.abs() * 1.3) {
        intent = _GestureIntent.send;
      } else {
        final now = DateTime.now();
        final seconds = (now.difference(lastDragTime!).inMicroseconds / 1e6)
            .clamp(.008, .1);
        final columns = -(event.localPosition.dx - last!.dx) / playWidth * 12;
        model.dragColumns(columns);
        dragVelocity = (dragVelocity * .25 + columns / seconds * .75).clamp(
          -32,
          32,
        );
        lastDragTime = now;
      }
    }
    last = event.localPosition;
  }

  void _pointerUp(PointerUpEvent event) {
    if (!canPlay || down == null || event.pointer != activePointer) return;
    final delta = event.localPosition - down!;
    final upward = delta.dy < -35 && -delta.dy > delta.dx.abs() * 1.1;
    if (upward || (intent == _GestureIntent.send && delta.dy < -28)) {
      model.releaseSpin(0);
      model.hardDrop();
    } else if (intent == _GestureIntent.turn) {
      final stale =
          DateTime.now().difference(lastDragTime!).inMilliseconds > 70;
      final flick = !stale && delta.dx.abs() > 55 && dragVelocity.abs() > 12;
      model.releaseSpin(flick ? dragVelocity : 0);
    } else {
      model.releaseSpin(0);
      if (!ascentGesture &&
          intent == _GestureIntent.pending &&
          maximumTravel < 12 &&
          delta.distance < 12 &&
          DateTime.now().difference(touchStarted!).inMilliseconds < 400) {
        _rotate(event.localPosition.dx < playWidth / 2 ? -1 : 1);
      }
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
                            child: Stack(
                              children: [
                                Positioned.fill(child: GameWidget(game: game)),
                                if (canPlay)
                                  _controls(constraints.maxHeight * .20),
                              ],
                            ),
                          ),
                        ),
                        if (started && !showBoard) _hud(),
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
              'CHANDELIER',
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
            _metric('GARDEN', '${model.rings} Rings'),
            _metric('GROWTH', '${model.plantHeight.toStringAsFixed(0)} cm'),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: model.occupancy,
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
                () => _rotate(-1),
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
                () => _rotate(1),
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
  }) {
    final direction = icon == Icons.rotate_left_rounded ? -1 : 1;
    final lit = hold ? model.softDrop : rotationFlash == direction;
    final visual = AnimatedContainer(
      key: ValueKey(hold ? 'ascent-control' : 'rotation-$direction'),
      duration: const Duration(milliseconds: 90),
      width: hold ? 76 : 62,
      height: hold ? 76 : 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hold
            ? (lit ? _mint : _cream).withValues(alpha: lit ? .18 : .06)
            : Colors.transparent,
        border: hold ? Border.all(color: _cream.withValues(alpha: .22)) : null,
      ),
      child: Icon(
        icon,
        size: hold ? 38 : (lit ? 34 : 29),
        color: lit ? _mint : _cream,
        shadows: lit
            ? [Shadow(color: _mint.withValues(alpha: .8), blurRadius: 16)]
            : null,
      ),
    );
    return Semantics(
      label: label,
      button: true,
      onTap: action,
      child: hold
          ? Listener(
              onPointerDown: (event) {
                if (!canPlay || activePointer != null) return;
                holdPointer = event.pointer;
                setState(() => model.softDrop = true);
              },
              onPointerUp: (event) {
                if (holdPointer == event.pointer) {
                  setState(() => model.softDrop = false);
                }
              },
              onPointerCancel: (event) {
                if (holdPointer == event.pointer) {
                  setState(() => model.softDrop = false);
                }
              },
              child: visual,
            )
          : IgnorePointer(child: visual),
    );
  }

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
          'Send pieces toward the light.\nMake room for your garden to grow.',
          style: TextStyle(
            fontSize: 13,
            height: 1.8,
            color: _cream.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 27),
        _button(
          'Grow a garden',
          () => _start(GameMode.unlimited),
          primary: true,
          icon: Icons.spa_outlined,
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
            _loadBoard();
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
    const eligible = true;
    return _sheet(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE GARDEN RESTS',
            style: const TextStyle(fontSize: 9, letterSpacing: 2, color: _mint),
          ),
          const SizedBox(height: 12),
          Text(
            model.won ? 'Room to flourish.' : 'A little more room next time.',
            style: const TextStyle(fontSize: 25, height: 1.3),
          ),
          const SizedBox(height: 20),
          Text(
            '30 Rings: ${model.thirtyRingTime == null ? '—' : _clock(model.thirtyRingTime!)}\nRings: ${model.rings}  ·  Monstera: ${model.plantHeight.toStringAsFixed(0)} cm',
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
              _loadBoard();
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
          Table(
            columnWidths: const {
              0: FlexColumnWidth(.8),
              1: FlexColumnWidth(1.3),
              2: FlexColumnWidth(.7),
              3: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                children: [
                  Text(''),
                  Text('30 Rings', style: TextStyle(fontSize: 10)),
                  Text('Rings', style: TextStyle(fontSize: 10)),
                  Text('Monstera', style: TextStyle(fontSize: 10)),
                ],
              ),
              for (final entry in table!.entries)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        entry.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      entry.time30 != null ? _clock(entry.time30!) : '—',
                      style: const TextStyle(fontSize: 11, color: _mint),
                    ),
                    Text(
                      '${entry.rings}',
                      style: const TextStyle(fontSize: 11, color: _mint),
                    ),
                    Text(
                      '${entry.height.toStringAsFixed(0)} cm',
                      style: const TextStyle(fontSize: 11, color: _mint),
                    ),
                  ],
                ),
            ],
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
