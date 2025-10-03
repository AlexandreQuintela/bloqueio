import 'package:flutter/material.dart';

import 'position.dart';

enum GoalSide { north, south, east, west }

class Player {
  Player({
    required this.id,
    required this.name,
    required this.color,
    required this.goalSide,
    required this.startPosition,
    required this.wallsRemaining,
    this.isBot = false,
  }) : position = startPosition;

  final int id;
  final String name;
  final Color color;
  final GoalSide goalSide;
  final Position startPosition;
  int wallsRemaining;
  Position position;
  final bool isBot;

  bool get hasWallsAvailable => wallsRemaining > 0;

  void useWall() {
    if (wallsRemaining <= 0) {
      throw StateError('Player $name is out of walls');
    }
    wallsRemaining -= 1;
  }

  void returnWall() {
    wallsRemaining += 1;
  }
}
