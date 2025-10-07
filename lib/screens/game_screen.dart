import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/jogador.dart';
import '../models/posicao.dart';
import '../models/jogo_quoridor.dart';
import '../models/parede.dart';
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
  late JogoQuoridor _game;
  Set<Posicao> _highlightedCells = <Posicao>{};
  Set<PosicionamentoParede> _highlightedWalls = <PosicionamentoParede>{};
  PosicionamentoParede? _previewWallPlacement;
  bool _showingWinnerDialog = false;

  @override
  void initState() {
    super.initState();
    _game = JogoQuoridor(
      quantidadeJogadores: widget.playerCount,
      idsBots: widget.botPlayerIds,
    );
    _refreshHighlights();
    _scheduleBotTurn();
  }

  void _refreshHighlights() {
    if (_game.jogoEncerrado) {
      _highlightedCells = <Posicao>{};
      _highlightedWalls = <PosicionamentoParede>{};
      _previewWallPlacement = null;
      return;
    }
    _highlightedCells = _game.movimentosLegaisPara(_game.jogadorAtual).toSet();
    if (_game.jogadorAtual.possuiParedesDisponiveis) {
      final horizontais = _game.posicionamentosLegais(
        OrientacaoParede.horizontal,
      );
      final verticais = _game.posicionamentosLegais(OrientacaoParede.vertical);
      _highlightedWalls = <PosicionamentoParede>{...horizontais, ...verticais};
    } else {
      _highlightedWalls = <PosicionamentoParede>{};
    }
    if (_previewWallPlacement != null &&
        !_highlightedWalls.contains(_previewWallPlacement)) {
      _previewWallPlacement = null;
    }
  }

  void _scheduleBotTurn() {
    if (!mounted || _game.jogoEncerrado) {
      return;
    }
    final current = _game.jogadorAtual;
    if (!current.ehAutomatizado) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _game.jogoEncerrado ||
          !_game.jogadorAtual.ehAutomatizado) {
        return;
      }
      _performBotTurn();
    });
  }

  Future<void> _performBotTurn() async {
    final bot = _game.jogadorAtual;
    if (!bot.ehAutomatizado || _game.jogoEncerrado) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (bot.possuiParedesDisponiveis) {
      final posicionouParede = _attemptBotWall(bot);
      if (posicionouParede) {
        if (!mounted) {
          return;
        }
        setState(_refreshHighlights);
        _scheduleBotTurn();
        return;
      }
    }

    final movimentos = _game.movimentosLegaisPara(bot);
    if (movimentos.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(_refreshHighlights);
      _scheduleBotTurn();
      return;
    }

    Posicao? alvo;
    final caminhoPlanejado = _game.menorCaminhoParaMeta(bot);
    if (caminhoPlanejado.length > 1) {
      final proximoPasso = caminhoPlanejado[1];
      if (movimentos.contains(proximoPasso)) {
        alvo = proximoPasso;
      }
    }

    if (alvo == null) {
      final posicaoOriginal = bot.posicaoAtual;
      var melhorPontuacao = 1 << 20;
      var melhorCentro = 1 << 20;
      for (final movimento in movimentos) {
        bot.moverPara(movimento);
        final caminhoFuturo = _game.menorCaminhoParaMeta(bot);
        bot.moverPara(posicaoOriginal);
        final pontuacao = caminhoFuturo.length;
        final pontuacaoCentro = _centerScore(movimento);
        if (pontuacao < melhorPontuacao ||
            (pontuacao == melhorPontuacao && pontuacaoCentro < melhorCentro)) {
          melhorPontuacao = pontuacao;
          melhorCentro = pontuacaoCentro;
          alvo = movimento;
        }
      }
      bot.moverPara(posicaoOriginal);
    }

    final destinoEscolhido = alvo ?? _chooseBotMove(bot, movimentos);

    var movimentou = _game.moverJogadorAtual(destinoEscolhido);
    if (!movimentou) {
      for (final alternativa in movimentos) {
        if (alternativa == destinoEscolhido) {
          continue;
        }
        if (_game.moverJogadorAtual(alternativa)) {
          movimentou = true;
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

  bool _attemptBotWall(Jogador bot) {
    final opponents = _game.jogadores
        .where((player) => !identical(player, bot))
        .toList();
    if (opponents.isEmpty) {
      return false;
    }

    final myPathLength = _game.menorCaminhoParaMeta(bot).length;
    final opponentPaths = <Jogador, int>{
      for (final opponent in opponents)
        opponent: _game.menorCaminhoParaMeta(opponent).length,
    };

    final candidates = <PosicionamentoParede>[
      ..._game.posicionamentosLegais(OrientacaoParede.horizontal),
      ..._game.posicionamentosLegais(OrientacaoParede.vertical),
    ];

    PosicionamentoParede? bestPlacement;
    var bestScore = 0;

    for (final placement in candidates) {
      final botPathAfter = _game.comprimentoCaminhoComParede(bot, placement);
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
        final projected = _game.comprimentoCaminhoComParede(
          opponent,
          placement,
        );
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
      return _game.posicionarParedeParaJogadorAtual(bestPlacement);
    }
    return false;
  }

  Posicao _chooseBotMove(Jogador bot, List<Posicao> moves) {
    var best = moves.first;
    var bestScore = _goalDistance(best, bot.ladoMeta);
    var bestCenter = _centerScore(best);

    for (final candidate in moves.skip(1)) {
      final distance = _goalDistance(candidate, bot.ladoMeta);
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

  int _goalDistance(Posicao position, LadoMeta goal) {
    switch (goal) {
      case LadoMeta.norte:
        return position.linha;
      case LadoMeta.sul:
        return _game.tamanhoTabuleiro - 1 - position.linha;
      case LadoMeta.leste:
        return _game.tamanhoTabuleiro - 1 - position.coluna;
      case LadoMeta.oeste:
        return position.coluna;
    }
  }

  int _centerScore(Posicao position) {
    final center = (_game.tamanhoTabuleiro - 1) / 2;
    final dRow = (position.linha - center).abs();
    final dCol = (position.coluna - center).abs();
    return (dRow + dCol).round();
  }

  void _handleCellTap(Posicao position) {
    if (_game.jogadorAtual.ehAutomatizado) {
      return;
    }
    final moved = _game.moverJogadorAtual(position);
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

  void _handleWallPreview(PosicionamentoParede placement) {
    if (_game.jogadorAtual.ehAutomatizado || _game.jogoEncerrado) {
      return;
    }
    if (_previewWallPlacement == placement) {
      return;
    }
    setState(() {
      _previewWallPlacement = placement.copiarCom(cor: _game.jogadorAtual.cor);
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

  void _handleWallCommit(PosicionamentoParede placement) {
    if (_game.jogadorAtual.ehAutomatizado) {
      return;
    }
    final coloredPlacement = placement.copiarCom(cor: _game.jogadorAtual.cor);
    final placed = _game.posicionarParedeParaJogadorAtual(coloredPlacement);
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
    if (!_game.jogoEncerrado || _showingWinnerDialog) {
      return;
    }
    _showingWinnerDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final winner = _game.vencedor;
          return AlertDialog(
            title: const Text('Fim de jogo!'),
            content: Text(
              winner != null
                  ? '${winner.nome} chegou ao objetivo e venceu!'
                  : 'Fim de jogo.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _game.reiniciar();
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
    final currentPlayer = _game.jogadorAtual;

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
                corJogadorAtual: currentPlayer.cor,
                paredeEmPreVisualizacao: _previewWallPlacement,
                aoPreVisualizarParede: _handleWallPreview,
                aoConfirmarParede: _handleWallCommit,
                aoCancelarPreVisualizacao: _handleWallPreviewCancel,
                permitirInteracaoCasas:
                    !_game.jogadorAtual.ehAutomatizado && !_game.jogoEncerrado,
                permitirInteracaoParedes:
                    !_game.jogadorAtual.ehAutomatizado &&
                    _game.jogadorAtual.possuiParedesDisponiveis &&
                    !_game.jogoEncerrado,
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
    Jogador currentPlayer, {
    required bool isCompact,
    double density = 1.0,
  }) {
    final accentColor = currentPlayer.cor;
    final isGameOver = _game.jogoEncerrado;
    final winnerName = _game.vencedor?.nome;
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
                        ? (winnerName ?? currentPlayer.nome)
                        : currentPlayer.nome,
                    style: nameStyle,
                  ),
                ],
              ),
            ),
            SizedBox(width: gap),
            _IndicadorParedes(
              paredesRestantes: currentPlayer.paredesRestantes,
              density: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorParedes extends StatelessWidget {
  const _IndicadorParedes({
    required this.paredesRestantes,
    required this.density,
  });

  final int paredesRestantes;
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
              '$paredesRestantes',
              key: ValueKey<int>(paredesRestantes),
              style: countStyle,
            ),
          ),
        ],
      ),
    );
  }
}
