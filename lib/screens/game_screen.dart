import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/position.dart';
import '../models/quoridor_game.dart';
import '../models/wall.dart';
import '../widgets/quoridor_board.dart';

class QuoridorGameScreen extends StatefulWidget {
  const QuoridorGameScreen({
    super.key,
    required this.playerCount,
    this.botPlayerIds = const <int>{},
  });

  final int playerCount;
  final Set<int> botPlayerIds;

  @override
  State<QuoridorGameScreen> createState() => _QuoridorGameScreenState();
}

class _QuoridorGameScreenState extends State<QuoridorGameScreen> {
  late QuoridorGame _game;
  Set<Position> _highlightedCells = <Position>{};
  Set<WallPlacement> _highlightedWalls = <WallPlacement>{};
  WallPlacement? _previewWallPlacement;
  bool _showingWinnerDialog = false;

  @override
  void initState() {
    super.initState();
    _game = QuoridorGame(
      playerCount: widget.playerCount,
      botPlayerIds: widget.botPlayerIds,
    );
    _refreshHighlights();
    _scheduleBotTurn();
  }

  void _refreshHighlights() {
    if (_game.isGameOver) {
      _highlightedCells = <Position>{};
      _highlightedWalls = <WallPlacement>{};
      _previewWallPlacement = null;
      return;
    }
    _highlightedCells = _game.legalMovesForPlayer(_game.currentPlayer).toSet();
    if (_game.currentPlayer.hasWallsAvailable) {
      final horizontal = _game.legalWallPlacements(WallOrientation.horizontal);
      final vertical = _game.legalWallPlacements(WallOrientation.vertical);
      _highlightedWalls = <WallPlacement>{...horizontal, ...vertical};
    } else {
      _highlightedWalls = <WallPlacement>{};
    }
    if (_previewWallPlacement != null &&
        !_highlightedWalls.contains(_previewWallPlacement)) {
      _previewWallPlacement = null;
    }
  }

  void _scheduleBotTurn() {
    if (!mounted || _game.isGameOver) {
      return;
    }
    final current = _game.currentPlayer;
    if (!current.isBot) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _game.isGameOver || !_game.currentPlayer.isBot) {
        return;
      }
      _performBotTurn();
    });
  }

  Future<void> _performBotTurn() async {
    final bot = _game.currentPlayer;
    if (!bot.isBot || _game.isGameOver) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (bot.hasWallsAvailable) {
      final placedWall = _attemptBotWall(bot);
      if (placedWall) {
        if (!mounted) {
          return;
        }
        setState(_refreshHighlights);
        _scheduleBotTurn();
        return;
      }
    }

    final moves = _game.legalMovesForPlayer(bot);
    if (moves.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _refreshHighlights();
      });
      _scheduleBotTurn();
      return;
    }

    Position? target;
    final plannedPath = _game.shortestPathToGoal(bot);
    if (plannedPath.length > 1) {
      final nextStep = plannedPath[1];
      if (moves.contains(nextStep)) {
        target = nextStep;
      }
    }

    if (target == null) {
      final originalPosition = bot.position;
      var bestScore = 1 << 20;
      var bestCenter = 1 << 20;
      for (final move in moves) {
        bot.position = move;
        final futurePath = _game.shortestPathToGoal(bot);
        bot.position = originalPosition;
        final score = futurePath.length;
        final centerScore = _centerScore(move);
        if (score < bestScore ||
            (score == bestScore && centerScore < bestCenter)) {
          bestScore = score;
          bestCenter = centerScore;
          target = move;
        }
      }
      bot.position = originalPosition;
    }

    final chosenTarget = target ?? _chooseBotMove(bot, moves);

    var moved = _game.moveCurrentPlayer(chosenTarget);
    if (!moved) {
      for (final fallback in moves) {
        if (fallback == chosenTarget) {
          continue;
        }
        if (_game.moveCurrentPlayer(fallback)) {
          moved = true;
          break;
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(_refreshHighlights);
    _maybeShowWinnerDialog();
    _scheduleBotTurn();
  }

  bool _attemptBotWall(Player bot) {
    final opponents = _game.players
        .where((player) => !identical(player, bot))
        .toList();
    if (opponents.isEmpty) {
      return false;
    }

    final myPathLength = _game.shortestPathToGoal(bot).length;
    final opponentPaths = <Player, int>{
      for (final opponent in opponents)
        opponent: _game.shortestPathToGoal(opponent).length,
    };

    final candidates = <WallPlacement>[
      ..._game.legalWallPlacements(WallOrientation.horizontal),
      ..._game.legalWallPlacements(WallOrientation.vertical),
    ];

    WallPlacement? bestPlacement;
    var bestScore = 0;

    for (final placement in candidates) {
      final botPathAfter = _game.pathLengthWithWall(bot, placement);
      final selfPenalty = botPathAfter - myPathLength;
      if (selfPenalty > 1) {
        continue;
      }

      var bestGain = 0;
      var affectsThreat = false;
      for (final opponent in opponents) {
        final originalLen = opponentPaths[opponent]!;
        if (originalLen > myPathLength + 1) {
          continue;
        }
        final projected = _game.pathLengthWithWall(opponent, placement);
        final gain = projected - originalLen;
        if (gain > 0) {
          affectsThreat = true;
          if (gain > bestGain) {
            bestGain = gain;
          }
        }
      }

      if (!affectsThreat || bestGain <= 0) {
        continue;
      }

      final score = bestGain * 2 - selfPenalty;
      if (score > bestScore) {
        bestScore = score;
        bestPlacement = placement;
      }
    }

    if (bestPlacement != null && bestScore > 0) {
      return _game.placeWallForCurrentPlayer(bestPlacement);
    }
    return false;
  }

  Position _chooseBotMove(Player bot, List<Position> moves) {
    var best = moves.first;
    var bestScore = _goalDistance(best, bot.goalSide);
    var bestCenter = _centerScore(best);

    for (final candidate in moves.skip(1)) {
      final distance = _goalDistance(candidate, bot.goalSide);
      final center = _centerScore(candidate);
      if (distance < bestScore ||
          (distance == bestScore && center < bestCenter)) {
        best = candidate;
        bestScore = distance;
        bestCenter = center;
      }
    }
    return best;
  }

  int _goalDistance(Position position, GoalSide goal) {
    switch (goal) {
      case GoalSide.north:
        return position.row;
      case GoalSide.south:
        return _game.boardSize - 1 - position.row;
      case GoalSide.east:
        return _game.boardSize - 1 - position.col;
      case GoalSide.west:
        return position.col;
    }
  }

  int _centerScore(Position position) {
    final center = (_game.boardSize - 1) / 2;
    final dRow = (position.row - center).abs();
    final dCol = (position.col - center).abs();
    return (dRow + dCol).round();
  }

  void _handleCellTap(Position position) {
    if (_game.currentPlayer.isBot) {
      return;
    }
    final moved = _game.moveCurrentPlayer(position);
    if (!moved) {
      _showFeedback('Movimento inválido nessa rodada.');
      return;
    }
    setState(() {
      _previewWallPlacement = null;
      _refreshHighlights();
    });
    _maybeShowWinnerDialog();
    _scheduleBotTurn();
  }

  void _handleWallPreview(WallPlacement placement) {
    if (_game.currentPlayer.isBot || _game.isGameOver) {
      return;
    }
    if (_previewWallPlacement == placement) {
      return;
    }
    setState(() {
      _previewWallPlacement = placement.copyWith(
        color: _game.currentPlayer.color,
      );
    });
  }

  void _handleWallPreviewCancel() {
    if (_previewWallPlacement == null) {
      return;
    }
    setState(() {
      _previewWallPlacement = null;
    });
  }

  void _handleWallCommit(WallPlacement placement) {
    if (_game.currentPlayer.isBot) {
      return;
    }
    final coloredPlacement = placement.copyWith(
      color: _game.currentPlayer.color,
    );
    final placed = _game.placeWallForCurrentPlayer(coloredPlacement);
    if (!placed) {
      setState(() {
        _previewWallPlacement = null;
        _refreshHighlights();
      });
      _showFeedback('Não é possível posicionar uma barreira ali.');
      return;
    }

    setState(() {
      _previewWallPlacement = null;
      _refreshHighlights();
    });
    _scheduleBotTurn();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _maybeShowWinnerDialog() {
    if (!_game.isGameOver || _showingWinnerDialog) {
      return;
    }
    _showingWinnerDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final winner = _game.winner;
          return AlertDialog(
            title: const Text('Fim de jogo!'),
            content: Text(
              winner != null
                  ? '${winner.name} chegou ao objetivo e venceu!'
                  : 'Fim de jogo.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _game.resetToInitialState();
                    _refreshHighlights();
                  });
                  _showingWinnerDialog = false;
                  _scheduleBotTurn();
                },
                child: const Text('Jogar novamente'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  _showingWinnerDialog = false;
                },
                child: const Text('Voltar ao menu'),
              ),
            ],
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
        _showingWinnerDialog = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPlayer = _game.currentPlayer;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isPortrait = constraints.maxHeight >= constraints.maxWidth;

              final tabuleiro = TabuleiroQuoridor(
                jogo: _game,
                casasDestacadas: _highlightedCells,
                paredesDestacadas: _highlightedWalls,
                aoToqueEmCasa: _handleCellTap,
                corJogadorAtual: currentPlayer.color,
                paredeEmPreVisualizacao: _previewWallPlacement,
                aoPreVisualizarParede: _handleWallPreview,
                aoConfirmarParede: _handleWallCommit,
                aoCancelarPreVisualizacao: _handleWallPreviewCancel,
                permitirInteracaoCasas:
                    !_game.currentPlayer.isBot && !_game.isGameOver,
                permitirInteracaoParedes:
                    !_game.currentPlayer.isBot &&
                    _game.currentPlayer.hasWallsAvailable &&
                    !_game.isGameOver,
              );

              if (isPortrait) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: _buildPlayerBanner(
                        theme,
                        currentPlayer,
                        isCompact: false,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(child: tabuleiro),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 5,
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final dimension = math.min(
                            innerConstraints.maxHeight,
                            innerConstraints.maxWidth,
                          );
                          final boardSize = dimension.isFinite && dimension > 0
                              ? dimension * 0.95
                              : 360.0;

                          return Center(
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: tabuleiro,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, panelConstraints) {
                          final maxWidth = panelConstraints.maxWidth;
                          double panelWidth;
                          if (!maxWidth.isFinite || maxWidth <= 0) {
                            panelWidth = 280.0;
                          } else if (maxWidth < 200.0) {
                            panelWidth = maxWidth;
                          } else {
                            panelWidth = math.min(maxWidth, 360.0);
                          }
                          final density = (panelWidth / 280.0)
                              .clamp(0.7, 1.05)
                              .toDouble();

                          return Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: panelWidth,
                              child: _buildPlayerBanner(
                                theme,
                                currentPlayer,
                                isCompact: true,
                                density: density,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBanner(
    ThemeData theme,
    Player currentPlayer, {
    required bool isCompact,
    double density = 1.0,
  }) {
    final accentColor = currentPlayer.color;
    final isGameOver = _game.isGameOver;
    final winnerName = _game.winner?.name;
    final scale = density.clamp(0.7, 1.1).toDouble();
    final horizontalPadding = (isCompact ? 18.0 : 22.0) * scale;
    final verticalPadding = (isCompact ? 14.0 : 18.0) * scale;
    final avatarSize = (isCompact ? 48.0 : 56.0) * scale;
    final gap = (isCompact ? 14.0 : 18.0) * scale;
    final smallGap = 4.0 * scale.clamp(0.75, 1.2).toDouble();
    final bannerRadius = (isCompact ? 22.0 : 26.0) * (0.85 + 0.15 * scale);
    final blurRadius = (isCompact ? 18.0 : 22.0) * (0.75 + 0.25 * scale);
    final shadowOffsetY = 12.0 * scale.clamp(0.7, 1.0).toDouble();

    final labelBase =
        theme.textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final nameBase =
        theme.textTheme.headlineSmall ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

    final labelStyle = labelBase.copyWith(
      color: isCompact ? Colors.white.withValues(alpha: 0.8) : Colors.white70,
      letterSpacing: 0.8,
      fontSize: (labelBase.fontSize ?? 14) * scale,
    );
    final nameStyle = nameBase.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      fontSize: (nameBase.fontSize ?? 24) * scale,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCompact
            ? Colors.black.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(bannerRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: isCompact ? 0.4 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isCompact ? 0.18 : 0.28),
            blurRadius: blurRadius,
            offset: Offset(0, shadowOffsetY),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.38),
                    blurRadius: (isCompact ? 12.0 : 16.0) * scale,
                    offset: Offset(0, 8.0 * scale.clamp(0.7, 1.0).toDouble()),
                  ),
                ],
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGameOver ? 'Partida encerrada' : 'Jogador atual',
                    style: labelStyle,
                  ),
                  SizedBox(height: smallGap),
                  Text(
                    isGameOver
                        ? (winnerName ?? currentPlayer.name)
                        : currentPlayer.name,
                    style: nameStyle,
                  ),
                ],
              ),
            ),
            SizedBox(width: gap),
            _WallsCounter(
              wallsRemaining: currentPlayer.wallsRemaining,
              density: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _WallsCounter extends StatelessWidget {
  const _WallsCounter({required this.wallsRemaining, required this.density});

  final int wallsRemaining;
  final double density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = density.clamp(0.7, 1.1).toDouble();
    final padding = EdgeInsets.symmetric(
      horizontal: 18.0 * scale,
      vertical: 12.0 * scale,
    );
    final radius = BorderRadius.circular(18.0 * (0.85 + 0.15 * scale));
    final labelBase =
        theme.textTheme.labelMedium ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    final countBase =
        theme.textTheme.headlineSmall ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

    final labelStyle = labelBase.copyWith(
      color: Colors.white70,
      letterSpacing: 0.6,
      fontSize: (labelBase.fontSize ?? 13) * scale,
    );
    final countStyle = countBase.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      fontSize: (countBase.fontSize ?? 24) * scale,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Barreiras', style: labelStyle),
          SizedBox(height: 4.0 * scale.clamp(0.75, 1.2).toDouble()),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: Text(
              '$wallsRemaining',
              key: ValueKey<int>(wallsRemaining),
              style: countStyle,
            ),
          ),
        ],
      ),
    );
  }
}
