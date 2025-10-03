import 'package:flutter/material.dart';

import '../screens/game_screen.dart';

enum GameMode { twoPlayers, vsPhone, threePlayers, fourPlayers }

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  GameMode _selectedMode = GameMode.twoPlayers;

  void _startGame() {
    final mode = _selectedMode;
    late final int playerCount;
    late final Set<int> botPlayers;

    switch (mode) {
      case GameMode.twoPlayers:
        playerCount = 2;
        botPlayers = const <int>{};
        break;
      case GameMode.vsPhone:
        playerCount = 2;
        botPlayers = const <int>{1};
        break;
      case GameMode.threePlayers:
        playerCount = 3;
        botPlayers = const <int>{2};
        break;
      case GameMode.fourPlayers:
        playerCount = 4;
        botPlayers = const <int>{};
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoridorGameScreen(
          playerCount: playerCount,
          botPlayerIds: botPlayers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quoridor',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Leve o seu peão até o outro lado do tabuleiro e use barreiras para desviar seus adversários.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Escolha o modo de jogo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('2 jogadores'),
                              selected: _selectedMode == GameMode.twoPlayers,
                              onSelected: (_) {
                                setState(() {
                                  _selectedMode = GameMode.twoPlayers;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Jogador vs celular'),
                              selected: _selectedMode == GameMode.vsPhone,
                              onSelected: (_) {
                                setState(() {
                                  _selectedMode = GameMode.vsPhone;
                                });
                              },
                            ),
                          ChoiceChip(
                            label: const Text('Celular com 3 jogadores'),
                            selected: _selectedMode == GameMode.threePlayers,
                            onSelected: (_) {
                              setState(() {
                                _selectedMode = GameMode.threePlayers;
                              });
                            },
                          ),
                            ChoiceChip(
                              label: const Text('4 jogadores'),
                              selected: _selectedMode == GameMode.fourPlayers,
                              onSelected: (_) {
                                setState(() {
                                  _selectedMode = GameMode.fourPlayers;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF29C079),
                              foregroundColor: Colors.white,
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            child: const Text('Iniciar partida'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
