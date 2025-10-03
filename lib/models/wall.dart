import 'package:flutter/material.dart';

import 'parede.dart';

export 'parede.dart';

/// Mantém a API antiga `WallPlacement`/`WallOrientation`.
typedef WallPlacement = PosicionamentoParede;
typedef WallOrientation = OrientacaoParede;

extension WallPlacementCompatibility on PosicionamentoParede {
  int get row => linha;
  int get col => coluna;
  WallOrientation get orientation => orientacao;
  Color? get color => cor;

  WallPlacement copyWith({
    int? row,
    int? col,
    WallOrientation? orientation,
    Color? color,
  }) => copiarCom(linha: row, coluna: col, orientacao: orientation, cor: color);
}
