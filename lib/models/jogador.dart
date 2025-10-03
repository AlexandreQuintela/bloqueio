import 'package:flutter/material.dart';

import 'posicao.dart';

/// Define as metas possíveis para a movimentação dos jogadores.
enum LadoMeta { norte, sul, leste, oeste }

/// Entidade que encapsula estado e regras para manipulação de um jogador.
class Jogador {
  Jogador({
    required this.id,
    required this.nome,
    required this.cor,
    required this.ladoMeta,
    required Posicao posicaoInicial,
    required int quantidadeParedes,
    this.ehAutomatizado = false,
  }) : _posicaoInicial = posicaoInicial,
       _posicaoAtual = posicaoInicial,
       _estoqueInicialDeParedes = quantidadeParedes,
       _paredesRestantes = quantidadeParedes;

  final int id;
  final String nome;
  final Color cor;
  final LadoMeta ladoMeta;
  final bool ehAutomatizado;

  final Posicao _posicaoInicial;
  Posicao _posicaoAtual;

  final int _estoqueInicialDeParedes;
  int _paredesRestantes;

  Posicao get posicaoAtual => _posicaoAtual;
  Posicao get posicaoInicial => _posicaoInicial;

  int get paredesRestantes => _paredesRestantes;
  set paredesRestantes(int valor) {
    if (valor < 0) {
      throw ArgumentError('Quantidade de paredes não pode ser negativa.');
    }
    _paredesRestantes = valor;
  }

  bool get possuiParedesDisponiveis => _paredesRestantes > 0;

  void moverPara(Posicao destino) {
    _posicaoAtual = destino;
  }

  void consumirParede() {
    if (_paredesRestantes <= 0) {
      throw StateError('Jogador $nome não possui paredes disponíveis.');
    }
    _paredesRestantes -= 1;
  }

  void devolverParede() {
    _paredesRestantes += 1;
  }

  void reiniciar() {
    _paredesRestantes = _estoqueInicialDeParedes;
    _posicaoAtual = _posicaoInicial;
  }
}
