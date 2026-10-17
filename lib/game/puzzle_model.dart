import 'dart:math' as math;

enum GameMode { timed, unlimited }

class GridCell {
  const GridCell(this.column, this.row);
  final int column;
  final int row;
}

/// Rules use rows increasing downward and angles measured in column widths.
class PuzzleModel {
  PuzzleModel({this.mode = GameMode.timed, int? seed})
    : _random = math.Random(seed) {
    reset();
  }
  static const columns = 18;
  static const rows = 42;
  static const targetRings = 30;
  static const lockDelay = 0.5;
  final math.Random _random;
  GameMode mode;
  final List<List<int>> board = List.generate(
    rows,
    (_) => List.filled(columns, 0),
  );
  final List<int> _bag = [];
  final List<int> _queue = [];
  int activeType = 1;
  int _row = 39;
  int _rotation = 0;
  double angle = 0;
  double spinVelocity = 0;
  double _progress = 0;
  bool _dragging = false;
  int _lastTurn = 1;
  double contactTime = 0;
  int _resets = 0;
  int rings = 0;
  double elapsed = 0;
  bool finished = false;
  bool won = false;
  bool softDrop = false;
  List<int> lastClearedRows = [];
  int clearSerial = 0;
  double collisionBounce = 0;
  List<int> get nextPieces => List.unmodifiable(_queue.take(3));
  double get speed => 1 + 0.55 * math.log(1 + rings / 5);
  double get plantHeight => rings.toDouble();

  /// Fraction of the next upward cell travelled, for visual interpolation.
  double get riseProgress =>
      _fits(_column, _row - 1, _rotation) ? _progress : 0;
  int get bestColumn => wrap(_column);
  bool get dragging => _dragging;
  double get occupancy =>
      board.expand((r) => r).where((c) => c != 0).length / (columns * rows);
  int get stackDepth {
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r].any((c) => c != 0)) return r + 1;
    }
    return 0;
  }

  int get _column => _nearest(angle - activeCenterOffset);

  /// Center of the rotated occupied cells, relative to their grid anchor.
  double get activeCenterOffset => _centerOffset(_rotation);

  /// Unwrapped occupied center selected by the current cylinder angle.
  double get activeCenterColumn => _column + activeCenterOffset;
  double _centerOffset(int rotation) {
    final cells = _localCells(rotation);
    final xs = cells.map((cell) => cell.column);
    return (xs.reduce(math.min) + xs.reduce(math.max)) / 2;
  }

  int _nearest(double value) =>
      (value + 0.5 - (_lastTurn < 0 ? 1e-9 : 0)).floor();
  static int wrap(int column) => column % columns;
  static const _shapes = [
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
    ],
    [
      [0, 0],
      [1, 0],
      [0, 1],
      [1, 1],
    ],
    [
      [1, 0],
      [0, 1],
      [1, 1],
      [2, 1],
    ],
    [
      [1, 0],
      [2, 0],
      [0, 1],
      [1, 1],
    ],
    [
      [0, 0],
      [1, 0],
      [1, 1],
      [2, 1],
    ],
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [2, 1],
    ],
    [
      [2, 0],
      [0, 1],
      [1, 1],
      [2, 1],
    ],
  ];
  static List<GridCell> cellsForType(int type) =>
      _shapes[type - 1].map((c) => GridCell(c[0], c[1])).toList();
  List<GridCell> _localCells(int rotation) {
    var cells = cellsForType(activeType);
    if (activeType != 2) {
      final size = activeType == 1 ? 4 : 3;
      for (var i = 0; i < rotation % 4; i++) {
        cells = cells.map((c) => GridCell(size - 1 - c.row, c.column)).toList();
      }
    }
    return cells;
  }

  List<GridCell> _cells(int column, int row, int rotation) {
    return _localCells(
      rotation,
    ).map((c) => GridCell(wrap(column + c.column), row + c.row)).toList();
  }

  List<GridCell> get activeCells => _cells(_column, _row, _rotation);
  List<GridCell> get landingCells {
    var row = _row;
    while (_fits(_column, row - 1, _rotation)) {
      row--;
    }
    return _cells(_column, row, _rotation);
  }

  bool _fits(int column, int row, int rotation) => _cells(
    column,
    row,
    rotation,
  ).every((c) => c.row >= 0 && c.row < rows && board[c.row][c.column] == 0);
  int _draw() {
    if (_bag.isEmpty) _bag.addAll([1, 2, 3, 4, 5, 6, 7]..shuffle(_random));
    return _bag.removeLast();
  }

  void reset({GameMode? mode}) {
    if (mode != null) this.mode = mode;
    for (final row in board) {
      row.fillRange(0, columns, 0);
    }
    _bag.clear();
    _queue.clear();
    rings = 0;
    elapsed = 0;
    finished = false;
    won = false;
    softDrop = false;
    _dragging = false;
    _lastTurn = 1;
    angle = 0;
    spinVelocity = 0;
    collisionBounce = 0;
    clearSerial = 0;
    lastClearedRows = [];
    _queue.addAll(List.generate(4, (_) => _draw()));
    _spawn();
  }

  void _spawn() {
    activeType = _queue.removeAt(0);
    _queue.add(_draw());
    _rotation = 0;
    _row = rows - 2;
    _progress = 0;
    contactTime = 0;
    _resets = 0;
    if (!_fits(_column, _row, _rotation)) finished = true;
  }

  void _adjusted() {
    if (contactTime > 0 && _resets < 15) {
      contactTime = 0;
      _resets++;
    }
  }

  void rotatePiece(int direction) {
    if (finished) return;
    final rotation = (_rotation + direction) % 4;
    final rotatedColumn = _nearest(angle - _centerOffset(rotation));
    for (final kick in const [
      [0, 0],
      [-1, 0],
      [1, 0],
      [-2, 0],
      [2, 0],
      [0, 1],
    ]) {
      if (_fits(rotatedColumn + kick[0], _row + kick[1], rotation)) {
        angle += kick[0];
        _row += kick[1];
        _rotation = rotation;
        _adjusted();
        return;
      }
    }
  }

  void dragColumns(double delta) {
    if (finished || !delta.isFinite) return;
    final target = angle + delta;
    final start = _column;
    if (delta != 0) _lastTurn = delta > 0 ? 1 : -1;
    final end = _nearest(target - activeCenterOffset);
    final direction = end >= start ? 1 : -1;
    for (
      var c = start + direction;
      direction > 0 ? c <= end : c >= end;
      c += direction
    ) {
      if (!_fits(c, _row, _rotation)) {
        angle = c - direction + activeCenterOffset;
        spinVelocity = 0;
        collisionBounce = -direction * 0.12;
        return;
      }
    }
    angle = target;
    if (start != end) _adjusted();
  }

  void beginDrag() {
    if (finished) return;
    _dragging = true;
    spinVelocity = 0;
  }

  void releaseSpin(double velocity) {
    _dragging = false;
    if (!finished && velocity.isFinite) spinVelocity = velocity.clamp(-40, 40);
  }

  void update(double dt) {
    if (finished || !dt.isFinite || dt <= 0) return;
    // Substeps preserve collision and timer behavior across slow frames.
    var remaining = dt;
    while (remaining > 0 && !finished) {
      final step = math.min(remaining, 1 / 60);
      remaining -= step;
      elapsed += step;
      collisionBounce *= math.exp(-step * 18);
      if (_dragging) {
        // Direct manipulation owns the angle until pointer release.
      } else if (spinVelocity.abs() > 0.03) {
        dragColumns(spinVelocity * step);
        spinVelocity *= math.exp(-3 * step);
      } else {
        spinVelocity = 0;
        dragColumns((_nearest(angle) - angle) * math.min(1, step * 12));
      }
      if (_fits(_column, _row - 1, _rotation)) {
        contactTime = 0;
        _progress += step * speed * (softDrop ? 12 : 1);
        while (_progress >= 1 && _fits(_column, _row - 1, _rotation)) {
          _row--;
          _progress--;
        }
        if (!_fits(_column, _row - 1, _rotation)) _progress = 0;
      } else {
        contactTime += step;
        if (contactTime + 1e-9 >= lockDelay) _lock();
      }
    }
  }

  void hardDrop() {
    if (finished) return;
    while (_fits(_column, _row - 1, _rotation)) {
      _row--;
    }
    _lock();
  }

  void _lock() {
    for (final c in activeCells) {
      board[c.row][c.column] = activeType;
    }
    lastClearedRows = [
      for (var r = 0; r < rows; r++)
        if (board[r].every((c) => c != 0)) r,
    ];
    if (lastClearedRows.isNotEmpty) {
      final remaining = [
        for (var r = 0; r < rows; r++)
          if (!lastClearedRows.contains(r)) List<int>.of(board[r]),
      ];
      remaining.addAll(
        List.generate(lastClearedRows.length, (_) => List.filled(columns, 0)),
      );
      for (var r = 0; r < rows; r++) {
        board[r].setAll(0, remaining[r]);
      }
      rings += lastClearedRows.length;
      clearSerial++;
    }
    if (mode == GameMode.timed && rings >= targetRings) {
      won = true;
      finished = true;
      return;
    }
    _spawn();
  }

  /// Deterministic fixture hook, also useful for interactive rules debugging.
  void debugSetActive({
    required int type,
    required int column,
    required int row,
    int rotation = 0,
  }) {
    activeType = type;
    _rotation = rotation;
    angle = column + activeCenterOffset;
    _row = row;
    _progress = 0;
    contactTime = 0;
    _resets = 0;
    spinVelocity = 0;
  }
}
