import 'package:flutter/material.dart';

import 'jogador.dart';
import 'posicao.dart';

export 'jogador.dart';

/// Enumerador mantido para compatibilidade com o código anterior.
enum GoalSide { north, south, east, west }

typedef Player = Jogador;

LadoMeta goalSideToLadoMeta(GoalSide side) {
  switch (side) {
    case GoalSide.north:
      return LadoMeta.norte;
    case GoalSide.south:
      return LadoMeta.sul;
    case GoalSide.east:
      return LadoMeta.leste;
    case GoalSide.west:
      return LadoMeta.oeste;
  }
}

GoalSide ladoMetaToGoalSide(LadoMeta lado) {
  switch (lado) {
    case LadoMeta.norte:
      return GoalSide.north;
    case LadoMeta.sul:
      return GoalSide.south;
    case LadoMeta.leste:
      return GoalSide.east;
    case LadoMeta.oeste:
      return GoalSide.west;
  }
}

extension PlayerCompatibility on Jogador {
  bool get isBot => ehAutomatizado;
  GoalSide get goalSide => ladoMetaToGoalSide(ladoMeta);
  Posicao get position => posicaoAtual;
  set position(Posicao value) => moverPara(value);
  bool get hasWallsAvailable => possuiParedesDisponiveis;
  int get wallsRemaining => paredesRestantes;
  set wallsRemaining(int value) => paredesRestantes = value;
  Posicao get startPosition => posicaoInicial;
  Color get color => cor;
  String get name => nome;

  void useWall() => consumirParede();
  void returnWall() => devolverParede();
}
