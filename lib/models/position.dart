import 'posicao.dart';

export 'posicao.dart';

/// Mantém a nomenclatura anterior `Position` para compatibilidade.
typedef Position = Posicao;

extension PositionCompatibility on Posicao {
  int get row => linha;
  int get col => coluna;
  Position translate(int dRow, int dCol) =>
      deslocar(deltaLinha: dRow, deltaColuna: dCol);
  bool isWithinBounds(int size) => estaDentroDosLimites(size);
  bool isAdjacent(Posicao other) => ehAdjacente(other);
}
