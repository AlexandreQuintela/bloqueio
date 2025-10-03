import 'package:flutter/material.dart';

/// Orientações possíveis para o posicionamento de uma parede.
enum OrientacaoParede { horizontal, vertical }

/// Dados de posicionamento e estilo de uma parede no tabuleiro.
@immutable
class PosicionamentoParede {
  const PosicionamentoParede({
    required this.linha,
    required this.coluna,
    required this.orientacao,
    this.cor,
  });

  final int linha;
  final int coluna;
  final OrientacaoParede orientacao;
  final Color? cor;

  bool get ehHorizontal => orientacao == OrientacaoParede.horizontal;

  PosicionamentoParede copiarCom({
    int? linha,
    int? coluna,
    OrientacaoParede? orientacao,
    Color? cor,
  }) {
    return PosicionamentoParede(
      linha: linha ?? this.linha,
      coluna: coluna ?? this.coluna,
      orientacao: orientacao ?? this.orientacao,
      cor: cor ?? this.cor,
    );
  }

  PosicionamentoParede comCor(Color novaCor) => copiarCom(cor: novaCor);

  bool ocupaMesmoEspaco(PosicionamentoParede outra) =>
      linha == outra.linha &&
      coluna == outra.coluna &&
      orientacao == outra.orientacao;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PosicionamentoParede &&
        other.linha == linha &&
        other.coluna == coluna &&
        other.orientacao == orientacao;
  }

  @override
  int get hashCode =>
      linha.hashCode ^ (coluna.hashCode << 8) ^ orientacao.hashCode;

  @override
  String toString() =>
      'PosicionamentoParede(linha: $linha, coluna: $coluna, orientacao: $orientacao, cor: $cor)';
}
