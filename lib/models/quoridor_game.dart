import 'dart:collection';

import 'package:flutter/material.dart';

import 'player.dart';
import 'position.dart';
import 'wall.dart';

class QuoridorGame {
  QuoridorGame({
    this.boardSize = 9,
    required int playerCount,
    Set<int>? botPlayerIds,
  }) : assert(
         const {2, 3, 4}.contains(playerCount),
         'Apenas partidas com 2, 3 ou 4 jogadores são suportadas.',
       ) {
    _botPlayerIds = Set<int>.from(botPlayerIds ?? const <int>{});
    assert(
      _botPlayerIds.every((id) => id >= 0 && id < playerCount),
      'Índices de bot fora do intervalo do número de jogadores.',
    );
    _players = _createPlayers(playerCount);
  }

  final int boardSize;
  late final List<Player> _players;
  late final Set<int> _botPlayerIds;
  final Set<WallPlacement> _horizontalWalls = <WallPlacement>{};
  final Set<WallPlacement> _verticalWalls = <WallPlacement>{};
  final Set<_Edge> _blockedEdges = <_Edge>{};
  int _currentPlayerIndex = 0;
  Player? winner;

  List<Player> get players => List.unmodifiable(_players);
  Player get currentPlayer => _players[_currentPlayerIndex];
  Set<WallPlacement> get horizontalWalls => Set.unmodifiable(_horizontalWalls);
  Set<WallPlacement> get verticalWalls => Set.unmodifiable(_verticalWalls);

  bool get isGameOver => winner != null;

  bool moveCurrentPlayer(Position target) {
    if (isGameOver) return false;
    final player = currentPlayer;
    final legalMoves = legalMovesForPlayer(player);
    if (!legalMoves.contains(target)) {
      return false;
    }

    player.position = target;
    if (_didPlayerWin(player)) {
      winner = player;
    } else {
      _advanceTurn();
    }
    return true;
  }

  bool placeWallForCurrentPlayer(WallPlacement placement) {
    if (isGameOver) return false;
    final player = currentPlayer;
    if (!player.hasWallsAvailable) return false;
    if (!isWallPlacementValid(placement)) {
      return false;
    }

    final targetSet = placement.orientation == WallOrientation.horizontal
        ? _horizontalWalls
        : _verticalWalls;
    final segments = _wallSegments(placement);

    final coloredPlacement = placement.color == null
        ? placement.copyWith(color: player.color)
        : placement;

    targetSet.add(coloredPlacement);
    _blockedEdges.addAll(segments);
    player.useWall();
    _advanceTurn();
    return true;
  }

  bool isWallPlacementValid(WallPlacement placement) {
    if (!_isPlacementWithinBoard(placement)) {
      return false;
    }

    final targetSet = placement.orientation == WallOrientation.horizontal
        ? _horizontalWalls
        : _verticalWalls;

    if (targetSet.contains(placement)) {
      return false;
    }

    if (_wouldCrossExistingWall(placement)) {
      return false;
    }

    final segments = _wallSegments(placement);
    if (segments.any(_blockedEdges.contains)) {
      // This covers overlaps caused by previously placed walls.
      return false;
    }

    final targetSetMut = placement.orientation == WallOrientation.horizontal
        ? _horizontalWalls
        : _verticalWalls;

    targetSetMut.add(placement);
    _blockedEdges.addAll(segments);

    final hasPaths = _players.every(_hasPathToGoal);

    targetSetMut.remove(placement);
    _blockedEdges.removeAll(segments);

    return hasPaths;
  }

  List<WallPlacement> legalWallPlacements(WallOrientation orientation) {
    final placements = <WallPlacement>[];
    for (var row = 0; row < boardSize - 1; row++) {
      for (var col = 0; col < boardSize - 1; col++) {
        final candidate = WallPlacement(
          row: row,
          col: col,
          orientation: orientation,
        );
        if (isWallPlacementValid(candidate)) {
          placements.add(candidate);
        }
      }
    }
    return placements;
  }

  List<Position> legalMovesForPlayer(Player player) {
    final occupancy = <Position, Player>{
      for (final p in _players) p.position: p,
    };

    final current = player.position;
    final moves = <Position>[];
    for (final dir in const <_Vector>[
      _Vector(-1, 0),
      _Vector(1, 0),
      _Vector(0, -1),
      _Vector(0, 1),
    ]) {
      final next = current.translate(dir.dRow, dir.dCol);
      if (!_isWithinBoard(next)) continue;
      if (_isBlocked(current, next)) continue;
      final occupant = occupancy[next];
      if (occupant == null) {
        moves.add(next);
        continue;
      }

      final jump = next.translate(dir.dRow, dir.dCol);
      if (_isWithinBoard(jump) &&
          !_isBlocked(next, jump) &&
          occupancy[jump] == null) {
        moves.add(jump);
      } else {
        for (final diag in _diagonalOffsets(dir)) {
          final diagonal = next.translate(diag.dRow, diag.dCol);
          if (!_isWithinBoard(diagonal)) continue;
          if (_isBlocked(next, diagonal)) continue;
          if (occupancy[diagonal] != null) continue;
          moves.add(diagonal);
        }
      }
    }
    return moves;
  }

  List<Position> shortestPathToGoal(Player player) {
    final start = player.position;
    final queue = Queue<Position>()..add(start);
    final cameFrom = <Position, Position?>{start: null};
    final blockedPositions = <Position>{
      for (final other in _players)
        if (!identical(other, player)) other.position,
    };

    Position? goalNode;
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (_reachedGoal(current, player.goalSide)) {
        goalNode = current;
        break;
      }

      for (final neighbor in _neighbors(current)) {
        if (blockedPositions.contains(neighbor)) {
          continue;
        }
        if (cameFrom.containsKey(neighbor)) {
          continue;
        }
        cameFrom[neighbor] = current;
        queue.add(neighbor);
      }
    }

    if (goalNode == null) {
      return <Position>[start];
    }

    return _reconstructPath(goalNode, cameFrom);
  }

  int pathLengthWithWall(Player player, WallPlacement placement) {
    return _withTemporaryWall(
      placement,
      () => shortestPathToGoal(player).length,
    );
  }

  void resetToInitialState() {
    _horizontalWalls.clear();
    _verticalWalls.clear();
    _blockedEdges.clear();
    final walls = _initialWallsForCount(_players.length);
    for (final player in _players) {
      player.wallsRemaining = walls;
      player.position = player.startPosition;
    }
    _currentPlayerIndex = 0;
    winner = null;
  }

  List<Player> _createPlayers(int playerCount) {
    final walls = _initialWallsForCount(playerCount);
    final positions = _initialPositions(playerCount);
    final colors = _playerColors(playerCount);
    final goals = _goalSides(playerCount);

    return List<Player>.generate(playerCount, (index) {
      final isBot = _botPlayerIds.contains(index);
      return Player(
        id: index,
        name: isBot ? 'Celular' : 'Jogador ${index + 1}',
        color: colors[index],
        goalSide: goals[index],
        startPosition: positions[index],
        wallsRemaining: walls,
        isBot: isBot,
      );
    });
  }

  List<Position> _initialPositions(int count) {
    final lastIndex = boardSize - 1;
    final center = boardSize ~/ 2;
    switch (count) {
      case 2:
        return <Position>[Position(lastIndex, center), Position(0, center)];
      case 3:
        return <Position>[
          Position(lastIndex, center),
          Position(0, center),
          Position(center, 0),
        ];
      default:
        return <Position>[
          Position(lastIndex, center),
          Position(0, center),
          Position(center, 0),
          Position(center, lastIndex),
        ];
    }
  }

  List<Color> _playerColors(int count) {
    const palette = <Color>[
      Color(0xFFF2EFE2),
      Color(0xFFF2545B),
      Color(0xFF2E294E),
      Color(0xFFFFA630),
    ];
    return palette.take(count).toList(growable: false);
  }

  List<GoalSide> _goalSides(int count) {
    switch (count) {
      case 2:
        return const <GoalSide>[GoalSide.north, GoalSide.south];
      case 3:
        return const <GoalSide>[GoalSide.north, GoalSide.south, GoalSide.east];
      default:
        return const <GoalSide>[
          GoalSide.north,
          GoalSide.south,
          GoalSide.east,
          GoalSide.west,
        ];
    }
  }

  int _initialWallsForCount(int count) {
    switch (count) {
      case 2:
        return 10;
      case 3:
        return 7;
      default:
        return 5;
    }
  }

  bool _isPlacementWithinBoard(WallPlacement placement) {
    if (placement.row < 0 || placement.col < 0) return false;
    if (placement.row >= boardSize - 1 || placement.col >= boardSize - 1) {
      return false;
    }
    return true;
  }

  bool _wouldCrossExistingWall(WallPlacement placement) {
    if (placement.orientation == WallOrientation.horizontal) {
      return _verticalWalls.contains(
        WallPlacement(
          row: placement.row,
          col: placement.col,
          orientation: WallOrientation.vertical,
        ),
      );
    }
    return _horizontalWalls.contains(
      WallPlacement(
        row: placement.row,
        col: placement.col,
        orientation: WallOrientation.horizontal,
      ),
    );
  }

  bool _hasPathToGoal(Player player) {
    final visited = <Position>{};
    final queue = Queue<Position>()..add(player.position);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (visited.contains(current)) continue;
      visited.add(current);
      if (_reachedGoal(current, player.goalSide)) {
        return true;
      }

      for (final neighbor in _neighbors(current)) {
        if (!visited.contains(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    return false;
  }

  Iterable<Position> _neighbors(Position position) sync* {
    for (final dir in const <_Vector>[
      _Vector(-1, 0),
      _Vector(1, 0),
      _Vector(0, -1),
      _Vector(0, 1),
    ]) {
      final next = position.translate(dir.dRow, dir.dCol);
      if (_isWithinBoard(next) && !_isBlocked(position, next)) {
        yield next;
      }
    }
  }

  List<Position> _reconstructPath(
    Position end,
    Map<Position, Position?> cameFrom,
  ) {
    final path = <Position>[];
    Position? current = end;
    while (current != null) {
      path.add(current);
      current = cameFrom[current];
    }
    return path.reversed.toList(growable: false);
  }

  bool _reachedGoal(Position position, GoalSide goalSide) {
    switch (goalSide) {
      case GoalSide.north:
        return position.row == 0;
      case GoalSide.south:
        return position.row == boardSize - 1;
      case GoalSide.east:
        return position.col == boardSize - 1;
      case GoalSide.west:
        return position.col == 0;
    }
  }

  bool _didPlayerWin(Player player) =>
      _reachedGoal(player.position, player.goalSide);

  bool _isWithinBoard(Position position) => position.isWithinBounds(boardSize);

  bool _isBlocked(Position from, Position to) {
    if (!from.isAdjacent(to)) {
      return true;
    }
    return _blockedEdges.contains(_Edge(from, to));
  }

  List<_Vector> _diagonalOffsets(_Vector direction) {
    if (direction.dRow != 0) {
      return const <_Vector>[_Vector(0, -1), _Vector(0, 1)];
    }
    return const <_Vector>[_Vector(-1, 0), _Vector(1, 0)];
  }

  T _withTemporaryWall<T>(WallPlacement placement, T Function() action) {
    final targetSet = placement.orientation == WallOrientation.horizontal
        ? _horizontalWalls
        : _verticalWalls;
    final segments = _wallSegments(placement);
    targetSet.add(placement);
    _blockedEdges.addAll(segments);
    try {
      return action();
    } finally {
      _blockedEdges.removeAll(segments);
      targetSet.remove(placement);
    }
  }

  void _advanceTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
  }

  List<_Edge> _wallSegments(WallPlacement placement) {
    switch (placement.orientation) {
      case WallOrientation.horizontal:
        return <_Edge>[
          _Edge(
            Position(placement.row, placement.col),
            Position(placement.row + 1, placement.col),
          ),
          _Edge(
            Position(placement.row, placement.col + 1),
            Position(placement.row + 1, placement.col + 1),
          ),
        ];
      case WallOrientation.vertical:
        return <_Edge>[
          _Edge(
            Position(placement.row, placement.col),
            Position(placement.row, placement.col + 1),
          ),
          _Edge(
            Position(placement.row + 1, placement.col),
            Position(placement.row + 1, placement.col + 1),
          ),
        ];
    }
  }
}

class _Edge {
  _Edge(Position a, Position b)
    : assert(a.isAdjacent(b)),
      _a = _minPosition(a, b),
      _b = _maxPosition(a, b);

  final Position _a;
  final Position _b;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Edge && other._a == _a && other._b == _b;
  }

  @override
  int get hashCode => _a.hashCode ^ (_b.hashCode << 1);
}

Position _minPosition(Position a, Position b) {
  if (a.row < b.row) return a;
  if (a.row > b.row) return b;
  return a.col <= b.col ? a : b;
}

Position _maxPosition(Position a, Position b) {
  if (a.row > b.row) return a;
  if (a.row < b.row) return b;
  return a.col >= b.col ? a : b;
}

class _Vector {
  const _Vector(this.dRow, this.dCol);

  final int dRow;
  final int dCol;
}
