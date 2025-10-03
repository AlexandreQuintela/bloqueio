import 'package:flutter/material.dart';

enum WallOrientation { horizontal, vertical }

@immutable
class WallPlacement {
  const WallPlacement({
    required this.row,
    required this.col,
    required this.orientation,
    this.color,
  });

  final int row;
  final int col;
  final WallOrientation orientation;
  final Color? color;

  WallPlacement copyWith({
    int? row,
    int? col,
    WallOrientation? orientation,
    Color? color,
  }) {
    return WallPlacement(
      row: row ?? this.row,
      col: col ?? this.col,
      orientation: orientation ?? this.orientation,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallPlacement &&
        other.row == row &&
        other.col == col &&
        other.orientation == orientation;
  }

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 8) ^ orientation.hashCode;

  @override
  String toString() =>
      'WallPlacement(row: $row, col: $col, orientation: $orientation, color: $color)';
}
