import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/position.dart';
import '../models/quoridor_game.dart';
import '../models/wall.dart';

/// Widget responsável por renderizar o tabuleiro do Quoridor com destaques,
/// pré-visualizações de paredes e peões dos jogadores.
class TabuleiroQuoridor extends StatelessWidget {
  const TabuleiroQuoridor({
    super.key,
    required this.jogo,
    required this.casasDestacadas,
    required this.paredesDestacadas,
    required this.aoToqueEmCasa,
    required this.corJogadorAtual,
    this.paredeEmPreVisualizacao,
    this.aoPreVisualizarParede,
    this.aoConfirmarParede,
    this.aoCancelarPreVisualizacao,
    this.permitirInteracaoCasas = true,
    this.permitirInteracaoParedes = true,
  });

  // Paleta principal e estilos compartilhados.
  static const Color _corBaseTabuleiro = Color(0xFF0C1D3B);
  static const Color _corAcentoTabuleiro = Color(0xFF2A7BFF);
  static const Color _corGradienteExternoInicio = Color(0xFF1E3C72);
  static const Color _corGradienteExternoFim = Color(0xFF2A5298);
  static const Color _corParedePadrao = Color(0xFFD4A373);
  static const List<BoxShadow> _sombrasTabuleiro = <BoxShadow>[
    BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 12)),
  ];

  // Proporções e medidas gerais.
  static const double _proporcaoPadding = 0.04;
  static const double _proporcaoGap = 0.07;
  static const double _escalaEspessuraParede = 1.35;
  static const double _fatorEspessuraMinimaParede = 0.18;
  static const double _raioCantoTabuleiro = 32;
  static const double _raioCantoCasa = 14;
  static const double _raioCantoParede = 10;

  // Destaques de movimento.
  static const double _margemDestaqueMovimento = 0.1;
  static const double _raioRelativoDestaqueMovimento = 0.35;
  static const double _alphaPreenchimentoDestaqueMovimento = 0.08;
  static const double _alphaBordaDestaqueMovimento = 0.5;
  static const double _larguraBordaDestaqueMovimento = 1.6;
  static const double _alphaSombraDestaqueMovimento = 0.2;
  static const double _blurDestaqueMovimento = 6;
  static const double _spreadDestaqueMovimento = 1;

  // Casas do tabuleiro.
  static const double _alphaCasaDestacada = 0.18;
  static const double _alphaCasaPadrao = 0.78;
  static const double _alphaBordaCasaDestacada = 0.6;
  static const double _alphaBordaCasaPadrao = 0.15;
  static const double _larguraBordaCasaDestacada = 2;
  static const double _larguraBordaCasaPadrao = 1;

  // Peões.
  static const double _escalaPeao = 0.3;
  static const double _blurPeaoAtual = 14;
  static const double _blurPeaoInativo = 6;
  static const double _spreadPeaoAtual = 4;
  static const double _spreadPeaoInativo = 2;
  static const double _alphaSombraPeao = 0.5;
  static const double _alphaBordaPeaoAtual = 0.8;
  static const double _alphaBordaPeaoInativo = 0.4;
  static const double _larguraBordaPeaoAtual = 3;
  static const double _larguraBordaPeaoInativo = 1.5;

  // Pré-visualização das paredes.
  static const double _fatorExpansaoAreaParede = 0.2;
  static const double _escalaComprimentoParede = 1.08;
  static const double _escalaEspessuraParedeTransform = 1.08;
  static const double _alphaParedePreVisualizada = 0.9;
  static const double _alphaParedePadrao = 0.72;
  static const double _fatorGradienteParedeClaro = 0.18;
  static const double _fatorGradienteParedeEscuro = 0.22;
  static const double _alphaBordaParedePreVisualizada = 0.9;
  static const double _alphaBordaParedePadrao = 0.68;
  static const double _larguraBordaParedePreVisualizada = 1.7;
  static const double _larguraBordaParedePadrao = 1.1;
  static const double _alphaSombraParedePreVisualizada = 0.3;
  static const double _alphaSombraParedePadrao = 0.2;
  static const double _blurSombraParedePreVisualizada = 11;
  static const double _blurSombraParedePadrao = 7;
  static const double _offsetSombraParede = 3.6;
  static const double _spreadSombraParedePreVisualizada = -1;
  static const double _spreadSombraParedePadrao = -1.5;
  static const double _blurBrilhoPreVisualizacao = 8;
  static const double _offsetBrilhoPreVisualizacao = -0.8;
  static const double _spreadBrilhoPreVisualizacao = -2.3;

  // Temporizações.
  static const Duration _duracaoAnimacaoCasa = Duration(milliseconds: 150);
  static const Duration _duracaoAnimacaoParede = Duration(milliseconds: 120);
  static const Duration _duracaoAnimacaoPeao = Duration(milliseconds: 250);

  final QuoridorGame jogo;
  final Set<Position> casasDestacadas;
  final Set<WallPlacement> paredesDestacadas;
  final void Function(Position posicao) aoToqueEmCasa;

  /// Cor informativa do jogador atual (disponível para personalizações futuras).
  final Color corJogadorAtual;
  final WallPlacement? paredeEmPreVisualizacao;
  final void Function(WallPlacement posicionamento)? aoPreVisualizarParede;
  final void Function(WallPlacement posicionamento)? aoConfirmarParede;
  final VoidCallback? aoCancelarPreVisualizacao;
  final bool permitirInteracaoCasas;
  final bool permitirInteracaoParedes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (contexto, constraints) {
          final tamanhoDisponivel = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final padding = tamanhoDisponivel * _proporcaoPadding;
          final quantidadeCasas = jogo.boardSize;
          final areaUtil = tamanhoDisponivel - padding * 2;
          final gap =
              areaUtil * _proporcaoGap / (quantidadeCasas - 1).clamp(1, 9);
          final tamanhoCasa =
              (areaUtil - gap * (quantidadeCasas - 1)) / quantidadeCasas;
          final espessuraParede = math.max(
            gap * _escalaEspessuraParede,
            tamanhoCasa * _fatorEspessuraMinimaParede,
          );

          return Center(
            child: Container(
              width: tamanhoDisponivel,
              height: tamanhoDisponivel,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_raioCantoTabuleiro),
                gradient: const LinearGradient(
                  colors: <Color>[
                    _corGradienteExternoInicio,
                    _corGradienteExternoFim,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _sombrasTabuleiro,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _construirCasas(
                    padding: padding,
                    tamanhoCasa: tamanhoCasa,
                    gap: gap,
                  ),
                  _construirDestaquesMovimento(
                    padding: padding,
                    tamanhoCasa: tamanhoCasa,
                    gap: gap,
                  ),
                  _construirDestaquesParede(
                    padding: padding,
                    tamanhoCasa: tamanhoCasa,
                    gap: gap,
                    espessuraParede: espessuraParede,
                  ),
                  _construirParedes(
                    padding: padding,
                    tamanhoCasa: tamanhoCasa,
                    gap: gap,
                    espessuraParede: espessuraParede,
                  ),
                  _construirPeoes(
                    padding: padding,
                    tamanhoCasa: tamanhoCasa,
                    gap: gap,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói cada casa do tabuleiro, incluindo o destaque para casas válidas.
  Widget _construirCasas({
    required double padding,
    required double tamanhoCasa,
    required double gap,
  }) {
    final casas = <Widget>[];
    final corCasaPadrao = _corBaseTabuleiro.withValues(alpha: _alphaCasaPadrao);
    final corCasaDestacada = Colors.white.withValues(
      alpha: _alphaCasaDestacada,
    );
    final corBordaPadrao = Colors.white.withValues(
      alpha: _alphaBordaCasaPadrao,
    );
    final corBordaDestacada = Colors.white.withValues(
      alpha: _alphaBordaCasaDestacada,
    );

    for (var linha = 0; linha < jogo.boardSize; linha++) {
      for (var coluna = 0; coluna < jogo.boardSize; coluna++) {
        final posicao = Position(linha, coluna);
        final deslocamentoEsquerda = padding + coluna * (tamanhoCasa + gap);
        final deslocamentoTopo = padding + linha * (tamanhoCasa + gap);
        final estaDestacada = casasDestacadas.contains(posicao);

        casas.add(
          Positioned(
            left: deslocamentoEsquerda,
            top: deslocamentoTopo,
            width: tamanhoCasa,
            height: tamanhoCasa,
            child: GestureDetector(
              onTap: () {
                if (permitirInteracaoCasas && estaDestacada) {
                  aoToqueEmCasa(posicao);
                }
              },
              child: AnimatedContainer(
                duration: _duracaoAnimacaoCasa,
                decoration: BoxDecoration(
                  color: estaDestacada ? corCasaDestacada : corCasaPadrao,
                  borderRadius: BorderRadius.circular(_raioCantoCasa),
                  border: Border.all(
                    color: estaDestacada ? corBordaDestacada : corBordaPadrao,
                    width: estaDestacada
                        ? _larguraBordaCasaDestacada
                        : _larguraBordaCasaPadrao,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Stack(children: casas);
  }

  /// Destaca as casas válidas para movimento com um aro suave.
  Widget _construirDestaquesMovimento({
    required double padding,
    required double tamanhoCasa,
    required double gap,
  }) {
    if (casasDestacadas.isEmpty) {
      return const SizedBox.shrink();
    }

    final corPreenchimento = Colors.white.withValues(
      alpha: _alphaPreenchimentoDestaqueMovimento,
    );
    final corBorda = Colors.white.withValues(
      alpha: _alphaBordaDestaqueMovimento,
    );
    final sombra = BoxShadow(
      color: Colors.white.withValues(alpha: _alphaSombraDestaqueMovimento),
      blurRadius: _blurDestaqueMovimento,
      spreadRadius: _spreadDestaqueMovimento,
    );

    final destaques = <Widget>[];
    for (final posicao in casasDestacadas) {
      final deslocamentoEsquerda = padding + posicao.col * (tamanhoCasa + gap);
      final deslocamentoTopo = padding + posicao.row * (tamanhoCasa + gap);

      destaques.add(
        Positioned(
          left: deslocamentoEsquerda,
          top: deslocamentoTopo,
          width: tamanhoCasa,
          height: tamanhoCasa,
          child: IgnorePointer(
            child: Container(
              margin: EdgeInsets.all(tamanhoCasa * _margemDestaqueMovimento),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  tamanhoCasa * _raioRelativoDestaqueMovimento,
                ),
                color: corPreenchimento,
                border: Border.all(
                  color: corBorda,
                  width: _larguraBordaDestaqueMovimento,
                ),
                boxShadow: <BoxShadow>[sombra],
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: destaques);
  }

  /// Renderiza as paredes já posicionadas no tabuleiro.
  Widget _construirParedes({
    required double padding,
    required double tamanhoCasa,
    required double gap,
    required double espessuraParede,
  }) {
    final paredes = <Widget>[];

    for (final parede in jogo.horizontalWalls) {
      final deslocamentoEsquerda = padding + parede.col * (tamanhoCasa + gap);
      final deslocamentoTopo =
          padding + parede.row * (tamanhoCasa + gap) + tamanhoCasa;
      paredes.add(
        _construirPecaParede(
          deslocamentoEsquerda: deslocamentoEsquerda,
          deslocamentoTopo: deslocamentoTopo,
          largura: tamanhoCasa * 2 + gap,
          altura: espessuraParede,
          cor: parede.color ?? _corParedePadrao,
          ehHorizontal: true,
        ),
      );
    }

    for (final parede in jogo.verticalWalls) {
      final deslocamentoEsquerda =
          padding + parede.col * (tamanhoCasa + gap) + tamanhoCasa;
      final deslocamentoTopo = padding + parede.row * (tamanhoCasa + gap);
      paredes.add(
        _construirPecaParede(
          deslocamentoEsquerda: deslocamentoEsquerda,
          deslocamentoTopo: deslocamentoTopo,
          largura: espessuraParede,
          altura: tamanhoCasa * 2 + gap,
          cor: parede.color ?? _corParedePadrao,
          ehHorizontal: false,
        ),
      );
    }

    return Stack(children: paredes);
  }

  /// Constrói a camada de pré-visualização para posicionamento de paredes.
  Widget _construirDestaquesParede({
    required double padding,
    required double tamanhoCasa,
    required double gap,
    required double espessuraParede,
  }) {
    if (paredesDestacadas.isEmpty) {
      return const SizedBox.shrink();
    }

    final destaques = <Widget>[];

    for (final posicionamento in paredesDestacadas) {
      final ehHorizontal =
          posicionamento.orientation == WallOrientation.horizontal;
      final deslocamentoEsquerda =
          padding +
          posicionamento.col * (tamanhoCasa + gap) +
          (ehHorizontal ? 0 : tamanhoCasa);
      final deslocamentoTopo =
          padding +
          posicionamento.row * (tamanhoCasa + gap) +
          (ehHorizontal ? tamanhoCasa : 0);
      final largura = ehHorizontal ? tamanhoCasa * 2 + gap : espessuraParede;
      final altura = ehHorizontal ? espessuraParede : tamanhoCasa * 2 + gap;
      final expansao = tamanhoCasa * _fatorExpansaoAreaParede;
      final larguraExtra = ehHorizontal ? 0.0 : expansao;
      final alturaExtra = ehHorizontal ? expansao : 0.0;
      final alcanceEsquerda = deslocamentoEsquerda - larguraExtra / 2;
      final alcanceTopo = deslocamentoTopo - alturaExtra / 2;
      final alcanceLargura = largura + larguraExtra;
      final alcanceAltura = altura + alturaExtra;

      destaques.add(
        Positioned(
          left: alcanceEsquerda,
          top: alcanceTopo,
          width: alcanceLargura,
          height: alcanceAltura,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: permitirInteracaoParedes
                ? () {
                    if (paredeEmPreVisualizacao != null &&
                        paredeEmPreVisualizacao == posicionamento) {
                      aoConfirmarParede?.call(posicionamento);
                    } else {
                      aoPreVisualizarParede?.call(posicionamento);
                    }
                  }
                : null,
            onTapCancel: permitirInteracaoParedes
                ? () => aoCancelarPreVisualizacao?.call()
                : null,
            child: Center(
              child: SizedBox(
                width: largura,
                height: altura,
                child: _DestaqueParede(
                  ehHorizontal: ehHorizontal,
                  estaPreVisualizando:
                      paredeEmPreVisualizacao == posicionamento,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: destaques);
  }

  /// Renderiza os peões dos jogadores na posição corrente.
  Widget _construirPeoes({
    required double padding,
    required double tamanhoCasa,
    required double gap,
  }) {
    final peoes = <Widget>[];

    for (final jogador in jogo.players) {
      final posicao = jogador.position;
      final deslocamentoEsquerda =
          padding + posicao.col * (tamanhoCasa + gap) + tamanhoCasa / 2;
      final deslocamentoTopo =
          padding + posicao.row * (tamanhoCasa + gap) + tamanhoCasa / 2;
      final ehJogadorAtual =
          identical(jogador, jogo.currentPlayer) && !jogo.isGameOver;
      final blur = ehJogadorAtual ? _blurPeaoAtual : _blurPeaoInativo;
      final spread = ehJogadorAtual ? _spreadPeaoAtual : _spreadPeaoInativo;
      final alphaBorda = ehJogadorAtual
          ? _alphaBordaPeaoAtual
          : _alphaBordaPeaoInativo;
      final larguraBorda = ehJogadorAtual
          ? _larguraBordaPeaoAtual
          : _larguraBordaPeaoInativo;

      peoes.add(
        Positioned(
          left: deslocamentoEsquerda - tamanhoCasa * _escalaPeao,
          top: deslocamentoTopo - tamanhoCasa * _escalaPeao,
          width: tamanhoCasa * _escalaPeao * 2,
          height: tamanhoCasa * _escalaPeao * 2,
          child: AnimatedContainer(
            duration: _duracaoAnimacaoPeao,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: jogador.color,
              boxShadow: [
                BoxShadow(
                  color: jogador.color.withValues(alpha: _alphaSombraPeao),
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: alphaBorda),
                width: larguraBorda,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: peoes);
  }

  Positioned _construirPecaParede({
    required double deslocamentoEsquerda,
    required double deslocamentoTopo,
    required double largura,
    required double altura,
    required Color cor,
    required bool ehHorizontal,
  }) {
    return Positioned(
      left: deslocamentoEsquerda,
      top: deslocamentoTopo,
      width: largura,
      height: altura,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color.lerp(cor, Colors.white, _fatorGradienteParedeClaro) ?? cor,
              Color.lerp(cor, Colors.black, _fatorGradienteParedeClaro) ?? cor,
            ],
            begin: ehHorizontal ? Alignment.topCenter : Alignment.centerLeft,
            end: ehHorizontal ? Alignment.bottomCenter : Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(_raioCantoParede),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: cor.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Destaque visual utilizado durante a pré-visualização de posicionamento de paredes.
class _DestaqueParede extends StatelessWidget {
  const _DestaqueParede({
    required this.ehHorizontal,
    required this.estaPreVisualizando,
  });

  final bool ehHorizontal;
  final bool estaPreVisualizando;

  @override
  Widget build(BuildContext context) {
    final corPreenchimento =
        Color.lerp(
          TabuleiroQuoridor._corBaseTabuleiro,
          TabuleiroQuoridor._corAcentoTabuleiro,
          estaPreVisualizando ? 0.58 : 0.3,
        )!.withValues(
          alpha: estaPreVisualizando
              ? TabuleiroQuoridor._alphaParedePreVisualizada
              : TabuleiroQuoridor._alphaParedePadrao,
        );

    final corBordaGradienteClara = Color.lerp(
      corPreenchimento,
      Colors.white,
      TabuleiroQuoridor._fatorGradienteParedeClaro,
    )!;
    final corBordaGradienteEscura = Color.lerp(
      corPreenchimento,
      Colors.black,
      TabuleiroQuoridor._fatorGradienteParedeEscuro,
    )!;

    final corBorda = estaPreVisualizando
        ? Color.lerp(TabuleiroQuoridor._corAcentoTabuleiro, Colors.white, 0.35)!
        : Color.lerp(
            TabuleiroQuoridor._corBaseTabuleiro,
            TabuleiroQuoridor._corAcentoTabuleiro,
            0.18,
          )!;

    final gradiente = ehHorizontal
        ? LinearGradient(
            colors: <Color>[
              corBordaGradienteClara,
              corPreenchimento,
              corBordaGradienteEscura,
            ],
            stops: const <double>[0.0, 0.45, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: <Color>[
              corBordaGradienteClara,
              corPreenchimento,
              corBordaGradienteEscura,
            ],
            stops: const <double>[0.0, 0.45, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    // Expande ligeiramente a área destacada para cobrir as duas casas do encaixe.
    final escalaComprimento = ehHorizontal
        ? TabuleiroQuoridor._escalaComprimentoParede
        : 1.0;
    final escalaEspessura = ehHorizontal
        ? 1.0
        : TabuleiroQuoridor._escalaEspessuraParedeTransform;

    final sombraBase = TabuleiroQuoridor._corBaseTabuleiro.withValues(
      alpha: estaPreVisualizando
          ? TabuleiroQuoridor._alphaSombraParedePreVisualizada
          : TabuleiroQuoridor._alphaSombraParedePadrao,
    );

    final brilho = estaPreVisualizando
        ? Color.lerp(
            TabuleiroQuoridor._corAcentoTabuleiro,
            Colors.white,
            0.48,
          )!.withValues(alpha: 0.4)
        : null;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(escalaComprimento, escalaEspessura, 1),
      child: AnimatedContainer(
        duration: TabuleiroQuoridor._duracaoAnimacaoParede,
        decoration: BoxDecoration(
          gradient: gradiente,
          borderRadius: BorderRadius.circular(
            TabuleiroQuoridor._raioCantoParede,
          ),
          border: Border.all(
            color: corBorda.withValues(
              alpha: estaPreVisualizando
                  ? TabuleiroQuoridor._alphaBordaParedePreVisualizada
                  : TabuleiroQuoridor._alphaBordaParedePadrao,
            ),
            width: estaPreVisualizando
                ? TabuleiroQuoridor._larguraBordaParedePreVisualizada
                : TabuleiroQuoridor._larguraBordaParedePadrao,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: sombraBase,
              blurRadius: estaPreVisualizando
                  ? TabuleiroQuoridor._blurSombraParedePreVisualizada
                  : TabuleiroQuoridor._blurSombraParedePadrao,
              offset: const Offset(0, TabuleiroQuoridor._offsetSombraParede),
              spreadRadius: estaPreVisualizando
                  ? TabuleiroQuoridor._spreadSombraParedePreVisualizada
                  : TabuleiroQuoridor._spreadSombraParedePadrao,
            ),
            if (brilho != null)
              BoxShadow(
                color: brilho,
                blurRadius: TabuleiroQuoridor._blurBrilhoPreVisualizacao,
                offset: const Offset(
                  0,
                  TabuleiroQuoridor._offsetBrilhoPreVisualizacao,
                ),
                spreadRadius: TabuleiroQuoridor._spreadBrilhoPreVisualizacao,
              ),
          ],
        ),
      ),
    );
  }
}
