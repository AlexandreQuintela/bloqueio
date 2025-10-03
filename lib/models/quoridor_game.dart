import 'jogo_quoridor.dart';
import 'jogador.dart';
import 'parede.dart';
import 'posicao.dart';
import 'wall.dart';
import 'position.dart';
import 'player.dart';

export 'jogo_quoridor.dart';

/// Classe adaptadora que expõe a API original `QuoridorGame`.
class QuoridorGame extends JogoQuoridor {
  QuoridorGame({
    int boardSize = 9,
    required int playerCount,
    Set<int>? botPlayerIds,
  }) : super(
         tamanhoTabuleiro: boardSize,
         quantidadeJogadores: playerCount,
         idsBots: botPlayerIds,
       );

  List<Player> get players => jogadores;
  Player get currentPlayer => jogadorAtual;
  Set<WallPlacement> get horizontalWalls => paredesHorizontais;
  Set<WallPlacement> get verticalWalls => paredesVerticais;
  bool get isGameOver => jogoEncerrado;

  bool moveCurrentPlayer(Position destino) => moverJogadorAtual(destino);

  bool placeWallForCurrentPlayer(WallPlacement parede) =>
      posicionarParedeParaJogadorAtual(parede);

  bool isWallPlacementValid(WallPlacement parede) =>
      posicionamentoParedeEhValido(parede);

  List<WallPlacement> legalWallPlacements(WallOrientation orientacao) =>
      posicionamentosLegais(orientacao).toList();

  List<Position> legalMovesForPlayer(Player jogador) =>
      movimentosLegaisPara(jogador);

  List<Position> shortestPathToGoal(Player jogador) =>
      menorCaminhoParaMeta(jogador);

  int pathLengthWithWall(Player jogador, WallPlacement parede) =>
      comprimentoCaminhoComParede(jogador, parede);

  void resetToInitialState() => reiniciar();

  int get boardSize => tamanhoTabuleiro;
  Jogador? get winner => vencedor;
}
