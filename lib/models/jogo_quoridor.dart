import 'dart:collection';

import 'package:flutter/material.dart';

import 'jogador.dart';
import 'parede.dart';
import 'posicao.dart';

/// Implementação das regras centrais do Quoridor.
class JogoQuoridor {
  JogoQuoridor({
    this.tamanhoTabuleiro = 9,
    required int quantidadeJogadores,
    Set<int>? idsBots,
  }) : assert(
         const {2, 3, 4}.contains(quantidadeJogadores),
         'Apenas partidas com 2, 3 ou 4 jogadores são suportadas.',
       ) {
    _idsBots = Set<int>.from(idsBots ?? const <int>{});
    assert(
      _idsBots.every((id) => id >= 0 && id < quantidadeJogadores),
      'Índices de bot fora do intervalo do número de jogadores.',
    );
    _jogadores = _criarJogadores(quantidadeJogadores);
  }

  final int tamanhoTabuleiro;
  late final List<Jogador> _jogadores;
  late final Set<int> _idsBots;

  final Set<PosicionamentoParede> _paredesHorizontais =
      <PosicionamentoParede>{};
  final Set<PosicionamentoParede> _paredesVerticais = <PosicionamentoParede>{};
  final Set<_Aresta> _arestasBloqueadas = <_Aresta>{};

  int _indiceJogadorAtual = 0;
  Jogador? vencedor;

  List<Jogador> get jogadores => List.unmodifiable(_jogadores);
  Jogador get jogadorAtual => _jogadores[_indiceJogadorAtual];
  Set<PosicionamentoParede> get paredesHorizontais =>
      Set.unmodifiable(_paredesHorizontais);
  Set<PosicionamentoParede> get paredesVerticais =>
      Set.unmodifiable(_paredesVerticais);

  bool get jogoEncerrado => vencedor != null;

  bool moverJogadorAtual(Posicao destino) {
    if (jogoEncerrado) return false;
    final movimentos = movimentosLegaisPara(jogadorAtual);
    if (!movimentos.contains(destino)) {
      return false;
    }

    jogadorAtual.moverPara(destino);
    if (_atingiuMeta(jogadorAtual.posicaoAtual, jogadorAtual.ladoMeta)) {
      vencedor = jogadorAtual;
    } else {
      _avancarTurno();
    }
    return true;
  }

  bool posicionarParedeParaJogadorAtual(PosicionamentoParede parede) {
    if (jogoEncerrado) return false;
    if (!jogadorAtual.possuiParedesDisponiveis) return false;
    if (!posicionamentoParedeEhValido(parede)) {
      return false;
    }

    final conjunto = parede.ehHorizontal
        ? _paredesHorizontais
        : _paredesVerticais;
    final segmentos = _segmentosParede(parede);

    final paredeColorida = parede.cor == null
        ? parede.comCor(jogadorAtual.cor)
        : parede;

    conjunto.add(paredeColorida);
    _arestasBloqueadas.addAll(segmentos);
    jogadorAtual.consumirParede();
    _avancarTurno();
    return true;
  }

  bool posicionamentoParedeEhValido(PosicionamentoParede parede) {
    if (!_posicaoParedeDentroTabuleiro(parede)) {
      return false;
    }

    final conjunto = parede.ehHorizontal
        ? _paredesHorizontais
        : _paredesVerticais;

    if (conjunto.contains(parede)) {
      return false;
    }

    if (_cruzaParedeExistente(parede)) {
      return false;
    }

    final segmentos = _segmentosParede(parede);
    if (segmentos.any(_arestasBloqueadas.contains)) {
      return false;
    }

    conjunto.add(parede);
    _arestasBloqueadas.addAll(segmentos);
    final todosTemCaminho = _jogadores.every(_haCaminhoParaMeta);
    conjunto.remove(parede);
    _arestasBloqueadas.removeAll(segmentos);

    return todosTemCaminho;
  }

  List<PosicionamentoParede> posicionamentosLegais(
    OrientacaoParede orientacao,
  ) {
    final posicoes = <PosicionamentoParede>[];
    for (var linha = 0; linha < tamanhoTabuleiro - 1; linha++) {
      for (var coluna = 0; coluna < tamanhoTabuleiro - 1; coluna++) {
        final candidato = PosicionamentoParede(
          linha: linha,
          coluna: coluna,
          orientacao: orientacao,
        );
        if (posicionamentoParedeEhValido(candidato)) {
          posicoes.add(candidato);
        }
      }
    }
    return posicoes;
  }

  List<Posicao> movimentosLegaisPara(Jogador jogador) {
    final ocupacoes = <Posicao, Jogador>{
      for (final j in _jogadores) j.posicaoAtual: j,
    };

    final origem = jogador.posicaoAtual;
    final movimentos = <Posicao>[];
    for (final direcao in const <_Vetor>[
      _Vetor(-1, 0),
      _Vetor(1, 0),
      _Vetor(0, -1),
      _Vetor(0, 1),
    ]) {
      final proxima = origem.deslocar(
        deltaLinha: direcao.deltaLinha,
        deltaColuna: direcao.deltaColuna,
      );
      if (!_estaDentroDoTabuleiro(proxima)) continue;
      if (_estaBloqueado(origem, proxima)) continue;
      final ocupante = ocupacoes[proxima];
      if (ocupante == null) {
        movimentos.add(proxima);
        continue;
      }

      final salto = proxima.deslocar(
        deltaLinha: direcao.deltaLinha,
        deltaColuna: direcao.deltaColuna,
      );
      if (_estaDentroDoTabuleiro(salto) &&
          !_estaBloqueado(proxima, salto) &&
          ocupacoes[salto] == null) {
        movimentos.add(salto);
      } else {
        for (final diagonal in _deslocamentosDiagonais(direcao)) {
          final destinoDiagonal = proxima.deslocar(
            deltaLinha: diagonal.deltaLinha,
            deltaColuna: diagonal.deltaColuna,
          );
          if (!_estaDentroDoTabuleiro(destinoDiagonal)) continue;
          if (_estaBloqueado(proxima, destinoDiagonal)) continue;
          if (ocupacoes[destinoDiagonal] != null) continue;
          movimentos.add(destinoDiagonal);
        }
      }
    }
    return movimentos;
  }

  List<Posicao> menorCaminhoParaMeta(Jogador jogador) {
    final origem = jogador.posicaoAtual;
    final fila = Queue<Posicao>()..add(origem);
    final veioDe = <Posicao, Posicao?>{origem: null};
    final bloqueadas = <Posicao>{
      for (final outro in _jogadores)
        if (!identical(outro, jogador)) outro.posicaoAtual,
    };

    Posicao? metaEncontrada;
    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      if (_atingiuMeta(atual, jogador.ladoMeta)) {
        metaEncontrada = atual;
        break;
      }

      for (final vizinho in _vizinhos(atual)) {
        if (bloqueadas.contains(vizinho)) continue;
        if (veioDe.containsKey(vizinho)) continue;
        veioDe[vizinho] = atual;
        fila.add(vizinho);
      }
    }

    if (metaEncontrada == null) {
      return <Posicao>[origem];
    }

    return _reconstruirCaminho(metaEncontrada, veioDe);
  }

  int comprimentoCaminhoComParede(
    Jogador jogador,
    PosicionamentoParede parede,
  ) {
    return _comParedeTemporaria(
      parede,
      () => menorCaminhoParaMeta(jogador).length,
    );
  }

  void reiniciar() {
    _paredesHorizontais.clear();
    _paredesVerticais.clear();
    _arestasBloqueadas.clear();
    for (final jogador in _jogadores) {
      jogador.reiniciar();
    }
    _indiceJogadorAtual = 0;
    vencedor = null;
  }

  List<Jogador> _criarJogadores(int quantidade) {
    final posicoes = _posicoesIniciais(quantidade);
    final cores = _coresJogadores(quantidade);
    final metas = _ladosMeta(quantidade);
    final paredesIniciais = _quantidadeInicialParedes(quantidade);

    return List<Jogador>.generate(quantidade, (indice) {
      final ehBot = _idsBots.contains(indice);
      return Jogador(
        id: indice,
        nome: ehBot ? 'IA' : 'Jogador ${indice + 1}',
        cor: cores[indice],
        ladoMeta: metas[indice],
        posicaoInicial: posicoes[indice],
        quantidadeParedes: paredesIniciais,
        ehAutomatizado: ehBot,
      );
    });
  }

  List<Posicao> _posicoesIniciais(int quantidade) {
    final ultimaLinha = tamanhoTabuleiro - 1;
    final centro = tamanhoTabuleiro ~/ 2;
    switch (quantidade) {
      case 2:
        return <Posicao>[Posicao(ultimaLinha, centro), Posicao(0, centro)];
      case 3:
        return <Posicao>[
          Posicao(ultimaLinha, centro),
          Posicao(0, centro),
          Posicao(centro, 0),
        ];
      default:
        return <Posicao>[
          Posicao(ultimaLinha, centro),
          Posicao(0, centro),
          Posicao(centro, 0),
          Posicao(centro, ultimaLinha),
        ];
    }
  }

  List<Color> _coresJogadores(int quantidade) {
    const paleta = <Color>[
      Color.fromARGB(255, 217, 190, 70),
      Color(0xFFF2545B),
      Color(0xFF2E294E),
      Color(0xFFFFA630),
    ];
    return paleta.take(quantidade).toList(growable: false);
  }

  List<LadoMeta> _ladosMeta(int quantidade) {
    switch (quantidade) {
      case 2:
        return const <LadoMeta>[LadoMeta.norte, LadoMeta.sul];
      case 3:
        return const <LadoMeta>[LadoMeta.norte, LadoMeta.sul, LadoMeta.leste];
      default:
        return const <LadoMeta>[
          LadoMeta.norte,
          LadoMeta.sul,
          LadoMeta.leste,
          LadoMeta.oeste,
        ];
    }
  }

  int _quantidadeInicialParedes(int quantidadeJogadores) {
    switch (quantidadeJogadores) {
      case 2:
        return 10;
      case 3:
        return 7;
      default:
        return 5;
    }
  }

  bool _posicaoParedeDentroTabuleiro(PosicionamentoParede parede) {
    if (parede.linha < 0 || parede.coluna < 0) return false;
    if (parede.linha >= tamanhoTabuleiro - 1 ||
        parede.coluna >= tamanhoTabuleiro - 1) {
      return false;
    }
    return true;
  }

  bool _cruzaParedeExistente(PosicionamentoParede parede) {
    if (parede.ehHorizontal) {
      return _paredesVerticais.contains(
        PosicionamentoParede(
          linha: parede.linha,
          coluna: parede.coluna,
          orientacao: OrientacaoParede.vertical,
        ),
      );
    }
    return _paredesHorizontais.contains(
      PosicionamentoParede(
        linha: parede.linha,
        coluna: parede.coluna,
        orientacao: OrientacaoParede.horizontal,
      ),
    );
  }

  bool _haCaminhoParaMeta(Jogador jogador) {
    final visitados = <Posicao>{};
    final fila = Queue<Posicao>()..add(jogador.posicaoAtual);

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      if (visitados.contains(atual)) continue;
      visitados.add(atual);
      if (_atingiuMeta(atual, jogador.ladoMeta)) {
        return true;
      }

      for (final vizinho in _vizinhos(atual)) {
        if (!visitados.contains(vizinho)) {
          fila.add(vizinho);
        }
      }
    }
    return false;
  }

  Iterable<Posicao> _vizinhos(Posicao posicao) sync* {
    for (final direcao in const <_Vetor>[
      _Vetor(-1, 0),
      _Vetor(1, 0),
      _Vetor(0, -1),
      _Vetor(0, 1),
    ]) {
      final proxima = posicao.deslocar(
        deltaLinha: direcao.deltaLinha,
        deltaColuna: direcao.deltaColuna,
      );
      if (_estaDentroDoTabuleiro(proxima) &&
          !_estaBloqueado(posicao, proxima)) {
        yield proxima;
      }
    }
  }

  List<Posicao> _reconstruirCaminho(
    Posicao destino,
    Map<Posicao, Posicao?> veioDe,
  ) {
    final caminho = <Posicao>[];
    Posicao? atual = destino;
    while (atual != null) {
      caminho.add(atual);
      atual = veioDe[atual];
    }
    return caminho.reversed.toList(growable: false);
  }

  bool _atingiuMeta(Posicao posicao, LadoMeta ladoMeta) {
    switch (ladoMeta) {
      case LadoMeta.norte:
        return posicao.linha == 0;
      case LadoMeta.sul:
        return posicao.linha == tamanhoTabuleiro - 1;
      case LadoMeta.leste:
        return posicao.coluna == tamanhoTabuleiro - 1;
      case LadoMeta.oeste:
        return posicao.coluna == 0;
    }
  }

  bool _estaDentroDoTabuleiro(Posicao posicao) =>
      posicao.estaDentroDosLimites(tamanhoTabuleiro);

  bool _estaBloqueado(Posicao origem, Posicao destino) {
    if (!origem.ehAdjacente(destino)) {
      return true;
    }
    return _arestasBloqueadas.contains(_Aresta(origem, destino));
  }

  List<_Vetor> _deslocamentosDiagonais(_Vetor direcao) {
    if (direcao.deltaLinha != 0) {
      return const <_Vetor>[_Vetor(0, -1), _Vetor(0, 1)];
    }
    return const <_Vetor>[_Vetor(-1, 0), _Vetor(1, 0)];
  }

  T _comParedeTemporaria<T>(PosicionamentoParede parede, T Function() acao) {
    final conjunto = parede.ehHorizontal
        ? _paredesHorizontais
        : _paredesVerticais;
    final segmentos = _segmentosParede(parede);
    conjunto.add(parede);
    _arestasBloqueadas.addAll(segmentos);
    try {
      return acao();
    } finally {
      _arestasBloqueadas.removeAll(segmentos);
      conjunto.remove(parede);
    }
  }

  void _avancarTurno() {
    _indiceJogadorAtual = (_indiceJogadorAtual + 1) % _jogadores.length;
  }

  List<_Aresta> _segmentosParede(PosicionamentoParede parede) {
    final origem = Posicao(parede.linha, parede.coluna);
    if (parede.ehHorizontal) {
      return <_Aresta>[
        _Aresta(origem, origem.deslocar(deltaLinha: 1)),
        _Aresta(
          origem.deslocar(deltaColuna: 1),
          origem.deslocar(deltaLinha: 1, deltaColuna: 1),
        ),
      ];
    }
    return <_Aresta>[
      _Aresta(origem, origem.deslocar(deltaColuna: 1)),
      _Aresta(
        origem.deslocar(deltaLinha: 1),
        origem.deslocar(deltaLinha: 1, deltaColuna: 1),
      ),
    ];
  }
}

class _Aresta {
  _Aresta(Posicao a, Posicao b)
    : assert(a.ehAdjacente(b)),
      _a = _menorPosicao(a, b),
      _b = _maiorPosicao(a, b);

  final Posicao _a;
  final Posicao _b;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Aresta && other._a == _a && other._b == _b;
  }

  @override
  int get hashCode => _a.hashCode ^ (_b.hashCode << 1);
}

Posicao _menorPosicao(Posicao a, Posicao b) {
  if (a.linha < b.linha) return a;
  if (a.linha > b.linha) return b;
  return a.coluna <= b.coluna ? a : b;
}

Posicao _maiorPosicao(Posicao a, Posicao b) {
  if (a.linha > b.linha) return a;
  if (a.linha < b.linha) return b;
  return a.coluna >= b.coluna ? a : b;
}

class _Vetor {
  const _Vetor(this.deltaLinha, this.deltaColuna);

  final int deltaLinha;
  final int deltaColuna;
}
