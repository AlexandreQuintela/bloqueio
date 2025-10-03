import 'package:flutter/foundation.dart';

@immutable
class Position {
  const Position(this.row, this.col);

  final int row;
  final int col;

  Position translate(int dRow, int dCol) => Position(row + dRow, col + dCol);

  bool isWithinBounds(int size) =>
      row >= 0 && row < size && col >= 0 && col < size;

  bool isAdjacent(Position other) {
    final dRow = (row - other.row).abs();
    final dCol = (col - other.col).abs();
    return dRow + dCol == 1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 16);

  @override
  String toString() => 'Position(row: $row, col: $col)';
}
