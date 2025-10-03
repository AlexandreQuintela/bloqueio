import 'package:flutter/foundation.dart';

/// Representa uma coordenada no tabuleiro.
@immutable
class Posicao {
  const Posicao(this.linha, this.coluna);

  final int linha;
  final int coluna;

  Posicao deslocar({int deltaLinha = 0, int deltaColuna = 0}) =>
      Posicao(linha + deltaLinha, coluna + deltaColuna);

  bool estaDentroDosLimites(int tamanhoTabuleiro) =>
      linha >= 0 &&
      linha < tamanhoTabuleiro &&
      coluna >= 0 &&
      coluna < tamanhoTabuleiro;

  bool ehAdjacente(Posicao outra) {
    final deltaLinha = (linha - outra.linha).abs();
    final deltaColuna = (coluna - outra.coluna).abs();
    return deltaLinha + deltaColuna == 1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Posicao && other.linha == linha && other.coluna == coluna;
  }

  @override
  int get hashCode => linha.hashCode ^ (coluna.hashCode << 16);

  @override
  String toString() => 'Posicao(linha: $linha, coluna: $coluna)';
}
