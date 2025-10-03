import 'dart:math';

import 'package:flutter/material.dart';

import '../models/position.dart';
import '../models/quoridor_game.dart';
import '../models/wall.dart';

class QuoridorBoard extends StatelessWidget {
  const QuoridorBoard({
    super.key,
    required this.game,
    required this.highlightedCells,
    required this.highlightedWalls,
    required this.onCellTap,
    required this.currentPlayerColor,
    this.previewWall,
    this.onWallPreview,
    this.onWallCommit,
    this.onWallPreviewCancel,
    this.allowCellInteraction = true,
    this.allowWallInteraction = true,
  });

  final QuoridorGame game;
  final Set<Position> highlightedCells;
  final Set<WallPlacement> highlightedWalls;
  final void Function(Position position) onCellTap;
  final Color currentPlayerColor;
  final WallPlacement? previewWall;
  final void Function(WallPlacement placement)? onWallPreview;
  final void Function(WallPlacement placement)? onWallCommit;
  final VoidCallback? onWallPreviewCancel;
  final bool allowCellInteraction;
  final bool allowWallInteraction;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = min(constraints.maxWidth, constraints.maxHeight);
          final padding = size * 0.04;
          final boardSize = game.boardSize;
          final drawableSize = size - padding * 2;
          final gap = drawableSize * 0.07 / (boardSize - 1).clamp(1, 9);
          final cellSize = (drawableSize - gap * (boardSize - 1)) / boardSize;
          final wallThickness = max(gap * 1.35, cellSize * 0.18);

          return Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildCells(padding: padding, cellSize: cellSize, gap: gap),
                  _buildMoveHighlights(
                    padding: padding,
                    cellSize: cellSize,
                    gap: gap,
                  ),
                  _buildWalls(
                    padding: padding,
                    cellSize: cellSize,
                    gap: gap,
                    wallThickness: wallThickness,
                  ),
                  _buildWallHighlights(
                    padding: padding,
                    cellSize: cellSize,
                    gap: gap,
                    wallThickness: wallThickness,
                  ),
                  _buildPawns(padding: padding, cellSize: cellSize, gap: gap),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCells({
    required double padding,
    required double cellSize,
    required double gap,
  }) {
    final tiles = <Widget>[];
    for (var row = 0; row < game.boardSize; row++) {
      for (var col = 0; col < game.boardSize; col++) {
        final position = Position(row, col);
        final left = padding + col * (cellSize + gap);
        final top = padding + row * (cellSize + gap);
        final isHighlight = highlightedCells.contains(position);
        tiles.add(
          Positioned(
            left: left,
            top: top,
            width: cellSize,
            height: cellSize,
            child: GestureDetector(
              onTap: () {
                if (allowCellInteraction && isHighlight) {
                  onCellTap(position);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0xFF0C1D3B).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isHighlight ? 0.6 : 0.15,
                    ),
                    width: isHighlight ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Stack(children: tiles);
  }

  Widget _buildMoveHighlights({
    required double padding,
    required double cellSize,
    required double gap,
  }) {
    if (highlightedCells.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (final position in highlightedCells) {
      final left = padding + position.col * (cellSize + gap);
      final top = padding + position.row * (cellSize + gap);
      children.add(
        Positioned(
          left: left,
          top: top,
          width: cellSize,
          height: cellSize,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }

  Widget _buildWalls({
    required double padding,
    required double cellSize,
    required double gap,
    required double wallThickness,
  }) {
    final widgets = <Widget>[];
    for (final wall in game.horizontalWalls) {
      final left = padding + wall.col * (cellSize + gap);
      final top = padding + wall.row * (cellSize + gap) + cellSize;
      widgets.add(
        _buildWallTile(
          left: left,
          top: top,
          width: cellSize * 2 + gap,
          height: wallThickness,
          color: wall.color ?? const Color(0xFFD4A373),
          isHorizontal: true,
        ),
      );
    }
    for (final wall in game.verticalWalls) {
      final left = padding + wall.col * (cellSize + gap) + cellSize;
      final top = padding + wall.row * (cellSize + gap);
      widgets.add(
        _buildWallTile(
          left: left,
          top: top,
          width: wallThickness,
          height: cellSize * 2 + gap,
          color: wall.color ?? const Color(0xFFD4A373),
          isHorizontal: false,
        ),
      );
    }
    return Stack(children: widgets);
  }

  Widget _buildWallHighlights({
    required double padding,
    required double cellSize,
    required double gap,
    required double wallThickness,
  }) {
    if (highlightedWalls.isEmpty) {
      return const SizedBox.shrink();
    }
    final widgets = <Widget>[];
    for (final placement in highlightedWalls) {
      final isHorizontal = placement.orientation == WallOrientation.horizontal;
      final left =
          padding +
          placement.col * (cellSize + gap) +
          (isHorizontal ? 0 : cellSize);
      final top =
          padding +
          placement.row * (cellSize + gap) +
          (isHorizontal ? cellSize : 0);
      final width = isHorizontal ? cellSize * 2 + gap : wallThickness;
      final height = isHorizontal ? wallThickness : cellSize * 2 + gap;
      final expansion = cellSize * 0.2;
      final extraWidth = isHorizontal ? 0.0 : expansion;
      final extraHeight = isHorizontal ? expansion : 0.0;
      final hitLeft = left - extraWidth / 2;
      final hitTop = top - extraHeight / 2;
      final hitWidth = width + extraWidth;
      final hitHeight = height + extraHeight;
      widgets.add(
        Positioned(
          left: hitLeft,
          top: hitTop,
          width: hitWidth,
          height: hitHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: allowWallInteraction
                ? () {
                    if (previewWall != null && previewWall == placement) {
                      onWallCommit?.call(placement);
                    } else {
                      onWallPreview?.call(placement);
                    }
                  }
                : null,
            onTapCancel: allowWallInteraction
                ? () => onWallPreviewCancel?.call()
                : null,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: _WallHighlight(
                  isHorizontal: isHorizontal,
                  isPreview: previewWall != null && previewWall == placement,
                  color: previewWall?.color ?? currentPlayerColor,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: widgets);
  }

  Widget _buildPawns({
    required double padding,
    required double cellSize,
    required double gap,
  }) {
    final widgets = <Widget>[];
    for (final player in game.players) {
      final position = player.position;
      final left = padding + position.col * (cellSize + gap) + cellSize / 2;
      final top = padding + position.row * (cellSize + gap) + cellSize / 2;
      final isCurrent =
          identical(player, game.currentPlayer) && !game.isGameOver;
      widgets.add(
        Positioned(
          left: left - cellSize * 0.3,
          top: top - cellSize * 0.3,
          width: cellSize * 0.6,
          height: cellSize * 0.6,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.color,
              boxShadow: [
                BoxShadow(
                  color: player.color.withValues(alpha: 0.5),
                  blurRadius: isCurrent ? 14 : 6,
                  spreadRadius: isCurrent ? 4 : 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: isCurrent ? 0.8 : 0.4),
                width: isCurrent ? 3 : 1.5,
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: widgets);
  }

  Positioned _buildWallTile({
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color,
    required bool isHorizontal,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.18) ?? color,
              Color.lerp(color, Colors.black, 0.18) ?? color,
            ],
            begin: isHorizontal ? Alignment.topCenter : Alignment.centerLeft,
            end: isHorizontal ? Alignment.bottomCenter : Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallHighlight extends StatelessWidget {
  const _WallHighlight({
    required this.isHorizontal,
    required this.isPreview,
    required this.color,
  });

  final bool isHorizontal;
  final bool isPreview;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final borderColor = isPreview
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.3);
    final borderRadius = BorderRadius.circular(10);

    final gradient = isPreview
        ? LinearGradient(
            colors: [
              color.withValues(alpha: 0.92),
              Color.lerp(color, Colors.black, 0.2)!.withValues(alpha: 0.85),
            ],
            begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
            end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: isPreview ? 2.2 : 1.4),
        boxShadow: isPreview
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
    );
  }
}
