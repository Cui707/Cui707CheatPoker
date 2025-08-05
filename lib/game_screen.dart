// lib/game_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cui707cheatpoker/models/card.dart' as my_models;
import 'package:cui707cheatpoker/models/game.dart';
import 'package:cui707cheatpoker/models/player.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game game;
  List<my_models.Card> selectedCards = [];
  String _gameMessage = '游戏开始！';

  List<Map<String, dynamic>> currentPlayedCardsInfo = [];

  @override
  void initState() {
    super.initState();
    game = Game(playerNames: ['你', '玩家B', '玩家C']);
    _gameMessage = '游戏开始，轮到 ${game.currentPlayer.name} 出牌。';
    _checkPlayerTurn();
  }

  void _updateUI({String? message}) {
    setState(() {
      if (message != null) {
        _gameMessage = message;
      }
    });
    _checkPlayerTurn();
  }

  void _checkPlayerTurn() {
    if (game.currentPlayer.id != 0) {
      Future.delayed(const Duration(seconds: 2), () {
        _performAIAction();
      });
    }
  }
  
  void _performAIAction() {
    if (game.currentPlayer.id == 0) return;
    
    if (game.mustChallenge) {
      _onChallengeButtonPressed(isAI: true);
      return;
    }

    if (game.currentPlayer.cardCount == 0) {
      return;
    }

    List<my_models.Card> cardsToPlay;
    my_models.Rank calledRank;
    
    if (game.lastPlayedCards.isEmpty) {
      int maxCardsToPlay = min(game.currentPlayer.hand.length, 6);
      int cardsToPlayCount = Random().nextInt(maxCardsToPlay) + 1;
      cardsToPlay = game.currentPlayer.hand.sublist(0, cardsToPlayCount);
      
      final List<my_models.Rank> availableRanks = [
        my_models.Rank.two, my_models.Rank.three, my_models.Rank.four, my_models.Rank.five, my_models.Rank.six,
        my_models.Rank.seven, my_models.Rank.eight, my_models.Rank.nine, my_models.Rank.ten, my_models.Rank.jack,
        my_models.Rank.queen, my_models.Rank.king, my_models.Rank.ace,
      ];
      calledRank = availableRanks[Random().nextInt(availableRanks.length)];

    } else {
      double actionChoice = Random().nextDouble();
      if (actionChoice < 0.3) {
        _onChallengeButtonPressed(isAI: true);
        return;
      } else if (actionChoice < 0.6) {
        _onPassButtonPressed(isAI: true);
        return;
      } else {
        int maxCardsToPlay = min(game.currentPlayer.hand.length, 6);
        int cardsToPlayCount = Random().nextInt(maxCardsToPlay) + 1;
        cardsToPlay = game.currentPlayer.hand.sublist(0, cardsToPlayCount);
        
        final rankName = game.lastCalledRank;
        my_models.Rank? tempCalledRank;
        for (var rank in my_models.Rank.values) {
          if (rank.toString().split('.').last.toLowerCase() == rankName.toLowerCase()) {
            tempCalledRank = rank;
            break;
          }
        }
        calledRank = tempCalledRank ?? my_models.Rank.ace;
      }
    }
    
    List<Map<String, dynamic>> newCardsInfo = List.generate(
      cardsToPlay.length,
      (index) => {'player': game.currentPlayer.name, 'card': cardsToPlay[index], 'revealed': false},
    );
    currentPlayedCardsInfo.addAll(newCardsInfo);

    game.playCards(
      player: game.currentPlayer,
      cardsToPlay: cardsToPlay,
      calledRank: calledRank,
    );
    
    _updateUI(message: '${game.players[(game.currentPlayerIndex - 1 + game.players.length) % game.players.length].name} 出牌了 ${cardsToPlay.length} 张，并喊：${calledRank.toString().split('.').last.toUpperCase()}！\n轮到 ${game.currentPlayer.name}。');
  }

  void _onCardTapped(my_models.Card card) {
    if (game.currentPlayer.id == 0 && !game.mustChallenge) {
      setState(() {
        if (selectedCards.contains(card)) {
          selectedCards.remove(card);
        } else {
          if (selectedCards.length >= 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('一次最多只能出 6 张牌！')),
            );
            return;
          }
          selectedCards.add(card);
        }
      });
    }
  }

  void _showCallRankDialog() {
    if (selectedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要出的牌！')),
      );
      return;
    }
    
    final List<my_models.Rank> availableRanks = [
      my_models.Rank.two, my_models.Rank.three, my_models.Rank.four, my_models.Rank.five, my_models.Rank.six,
      my_models.Rank.seven, my_models.Rank.eight, my_models.Rank.nine, my_models.Rank.ten, my_models.Rank.jack,
      my_models.Rank.queen, my_models.Rank.king, my_models.Rank.ace,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('你要喊什么牌？'),
          content: Wrap(
            spacing: 8.0,
            children: availableRanks.map((rank) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _playSelectedCards(rank);
                },
                child: Text(rank.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _playSelectedCards(my_models.Rank? calledRank) {
    Player lastPlayer = game.currentPlayer;
    
    if (game.mustChallenge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上一位玩家出光了所有手牌，你必须质疑！')),
      );
      return;
    }

    List<Map<String, dynamic>> newCardsInfo = List.generate(
      selectedCards.length,
      (index) => {'player': lastPlayer.name, 'card': selectedCards[index], 'revealed': false},
    );
    currentPlayedCardsInfo.addAll(newCardsInfo);

    my_models.Rank finalCalledRank;
    if (calledRank == null) {
      final calledRankFromGame = my_models.Rank.values.firstWhere(
        (rank) => rank.toString().split('.').last.toLowerCase() == game.lastCalledRank.toLowerCase(),
        orElse: () => my_models.Rank.ace,
      );
      finalCalledRank = calledRankFromGame;
    } else {
      finalCalledRank = calledRank;
    }

    game.playCards(
      player: lastPlayer,
      cardsToPlay: selectedCards,
      calledRank: finalCalledRank,
    );

    _gameMessage = '${lastPlayer.name} 出牌了 ${selectedCards.length} 张，并喊：${finalCalledRank.toString().split('.').last.toUpperCase()}！\n轮到 ${game.currentPlayer.name}。';
    selectedCards.clear();
    _updateUI();
  }

  void _onPassButtonPressed({bool isAI = false}) {
    Player lastPlayer = game.currentPlayer;
    
    if (game.mustChallenge) {
      if (!isAI) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上一位玩家出光了所有手牌，你必须质疑！')),
        );
      }
      return;
    }

    bool roundEnded = game.passTurn(player: lastPlayer);
    
    if (roundEnded) {
      _gameMessage = '所有玩家都过牌了，本轮结束。\n由 ${game.currentPlayer.name} 开始新一轮。';
      currentPlayedCardsInfo.clear();
    } else {
      _gameMessage = '${lastPlayer.name} 选择过牌。\n轮到 ${game.currentPlayer.name}。';
    }
    _updateUI();
  }

  void _onChallengeButtonPressed({bool isAI = false}) {
    Player challenger = game.currentPlayer;
    Player liar = game.players[(game.currentPlayerIndex - 1 + game.players.length) % game.players.length];
    
    List<Map<String, dynamic>> newCardsInfo = List.generate(game.lastPlayedCards.length, (index) {
        return {'player': liar.name, 'card': game.lastPlayedCards[index], 'revealed': true};
    });
    currentPlayedCardsInfo.clear();
    currentPlayedCardsInfo.addAll(newCardsInfo);

    String? winnerName = game.challenge(challenger: challenger);
    
    if (winnerName != null) {
      _updateUI(message: '${challenger.name} 质疑失败！${liar.name} 确实出光了所有手牌。${winnerName} 赢得了游戏！');
      _showWinnerDialog(winnerName);
      currentPlayedCardsInfo.clear();
      return;
    }

    if (game.mustChallenge) {
      _updateUI(message: '${challenger.name} 质疑成功！${liar.name} 说谎了，拿走了所有牌。\n轮到 ${challenger.name} 开始新一轮。');
    } else {
      bool isLiar = game.players[(game.currentPlayerIndex - 1 + game.players.length) % game.players.length] == liar;
      if (isLiar) {
        _updateUI(message: '${challenger.name} 质疑成功！${liar.name} 说谎了，拿走了所有牌。\n由 ${challenger.name} 开始出牌。');
      } else {
        _updateUI(message: '${challenger.name} 质疑失败！${liar.name} 没有说谎，${challenger.name} 拿走了所有牌。\n由 ${liar.name} 开始出牌。');
      }
    }
    currentPlayedCardsInfo.clear();
  }

  void _checkWinner() {
    for (var player in game.players) {
      if (player.cardCount == 0) {
        return;
      }
    }
  }

  void _showWinnerDialog(String winnerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('游戏结束！'),
          content: Text('$winnerName 赢得了游戏！'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  game = Game(playerNames: ['你', '玩家B', '玩家C']);
                  _gameMessage = '游戏开始，轮到 ${game.currentPlayer.name} 出牌。';
                  selectedCards.clear();
                  currentPlayedCardsInfo.clear();
                });
              },
              child: const Text('重新开始'),
            ),
          ],
        );
      },
    );
  }
  
  String _getCardImagePath(my_models.Card card) {
    final suitNames = {
      my_models.Suit.clubs: 'Club',
      my_models.Suit.diamonds: 'Diamond',
      my_models.Suit.hearts: 'Heart',
      my_models.Suit.spades: 'Spade',
    };

    final rankNames = {
      my_models.Rank.two: '2',
      my_models.Rank.three: '3',
      my_models.Rank.four: '4',
      my_models.Rank.five: '5',
      my_models.Rank.six: '6',
      my_models.Rank.seven: '7',
      my_models.Rank.eight: '8',
      my_models.Rank.nine: '9',
      my_models.Rank.ten: '10',
      my_models.Rank.jack: 'J',
      my_models.Rank.queen: 'Q',
      my_models.Rank.king: 'K',
      my_models.Rank.ace: 'A',
    };

    String? suit = suitNames[card.suit];
    String? rank = rankNames[card.rank];

    if (suit == null || rank == null) {
      return 'assets/card_images/back.png';
    }

    return 'assets/card_images/$suit$rank.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('唬牌游戏')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerInfo(game.players[1]),
                  _buildCalledRankDisplay(),
                  _buildPlayerInfo(game.players[2]),
                ],
              ),
              
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildDiscardPileCount(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _gameMessage,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildCardPile(),
                  const SizedBox(height: 20),
                ],
              ),
              
              _buildPlayerArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(Player player) {
    bool shouldShowCount = player.id == 0 || player.cardCount < 5;
    
    return Column(
      children: [
        Text(player.name, style: const TextStyle(fontSize: 16)),
        if (shouldShowCount)
          Text('手牌数: ${player.cardCount}', style: const TextStyle(fontSize: 14)),
        if (!shouldShowCount && player.id != 0)
          const Text('手牌数: 未知', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        if (player.id != 0)
          Wrap(
            spacing: -20.0,
            children: List.generate(
              player.cardCount,
              (index) => Container(
                width: 40,
                height: 60,
                child: Image.asset(
                  'assets/card_images/back.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDiscardPileCount() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '弃牌堆: ${game.playedPile.length}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCalledRankDisplay() {
    return Column(
      children: [
        const Text('当前叫牌', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          game.lastCalledRank.isEmpty ? '无' : game.lastCalledRank.toUpperCase(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
  
  Widget _buildCardPile() {
    if (currentPlayedCardsInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          spacing: 4.0,
          children: currentPlayedCardsInfo.map((info) {
            final isRevealed = info['revealed'] as bool;
            final card = info['card'] as my_models.Card;
            final imagePath = isRevealed ? _getCardImagePath(card) : 'assets/card_images/back.png';
            
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  child: Image.asset(imagePath),
                ),
                Text(
                  '${info['player']}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPlayerArea() {
    Widget playerInfo = _buildPlayerInfo(game.players[0]);

    if (game.currentPlayer.id != 0) {
      return Column(
        children: [
          playerInfo,
          const SizedBox(height: 16),
          Text('等待 ${game.currentPlayer.name} 出牌...', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        ],
      );
    }
    
    final sortedHand = [...game.players[0].hand]..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    return Column(
      children: [
        playerInfo,
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: sortedHand.map((card) {
            final isSelected = selectedCards.contains(card);
            return GestureDetector(
              onTap: () => _onCardTapped(card),
              child: CardWidget(card: card, isSelected: isSelected, imagePath: _getCardImagePath(card)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (game.currentPlayer.id != 0) {
      return const SizedBox.shrink();
    }
    
    if (game.mustChallenge) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _onChallengeButtonPressed(),
            child: const Text('质疑'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: selectedCards.isNotEmpty
              ? (game.lastPlayedCards.isEmpty ? _showCallRankDialog : () => _playSelectedCards(null))
              : null,
          child: const Text('出牌'),
        ),
        ElevatedButton(
          onPressed: game.lastPlayedCards.isNotEmpty ? () => _onPassButtonPressed() : null,
          child: const Text('过牌'),
        ),
        ElevatedButton(
          onPressed: game.lastPlayedCards.isNotEmpty ? () => _onChallengeButtonPressed() : null,
          child: const Text('质疑'),
        ),
      ],
    );
  }
}

class CardWidget extends StatelessWidget {
  final my_models.Card card;
  final bool isSelected;
  final String imagePath;
  
  const CardWidget({Key? key, required this.card, this.isSelected = false, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected 
          ? BoxDecoration(
              border: Border.all(color: Colors.blue, width: 3),
              borderRadius: BorderRadius.circular(8),
            ) 
          : null,
      child: Image.asset(imagePath),
    );
  }
}