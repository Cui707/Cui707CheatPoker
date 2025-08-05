// lib/models/game.dart

import 'package:cui707cheatpoker/models/card.dart';
import 'package:cui707cheatpoker/models/player.dart';
import 'dart:math';

class Game {
  late List<Player> players;
  late List<Card> deck;
  List<Card> playedPile = [];
  List<Card> lastPlayedCards = [];
  String lastCalledRank = '';
  int currentPlayerIndex = 0;
  int playersPassedCount = 0;
  
  bool isHandCountVisible = false;
  bool mustChallenge = false;
  Player? lastPlayerToPlayAllCards;

  Game({required List<String> playerNames}) {
    _initialize(playerNames);
  }

  void _initialize(List<String> playerNames) {
    deck = _createDeck();
    deck.shuffle(Random());
    
    players = List.generate(
      playerNames.length,
      (index) => Player(id: index, name: playerNames[index]),
    );

    _dealCards();
    currentPlayerIndex = 0;
    playersPassedCount = 0;
    playedPile.clear();
    lastPlayedCards.clear();
    lastCalledRank = '';
    isHandCountVisible = false;
    mustChallenge = false;
    lastPlayerToPlayAllCards = null;
  }

  List<Card> _createDeck() {
    List<Card> newDeck = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        newDeck.add(Card(suit, rank));
      }
    }
    return newDeck;
  }

  void _dealCards() {
    int playerIndex = 0;
    while (deck.isNotEmpty) {
      players[playerIndex].addCards([deck.removeAt(0)]);
      playerIndex = (playerIndex + 1) % players.length;
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  Player get currentPlayer => players[currentPlayerIndex];

  void _checkHandCounts() {
    bool hasPlayerWithFewCards = false;
    for (var player in players) {
      if (player.cardCount < 5) {
        hasPlayerWithFewCards = true;
        break;
      }
    }
    isHandCountVisible = hasPlayerWithFewCards;
  }

  void playCards({required Player player, required List<Card> cardsToPlay, required Rank calledRank}) {
    if (player.id != currentPlayer.id) {
      throw Exception('不是该玩家的回合！');
    }
    if (!player.hasCards(cardsToPlay)) {
      throw Exception('玩家没有这些牌！');
    }
    
    if (mustChallenge) {
      throw Exception('必须对上一位玩家进行质疑！');
    }

    player.removeCards(cardsToPlay);
    
    lastPlayedCards.addAll(cardsToPlay);
    lastCalledRank = calledRank.toString().split('.').last;
    playersPassedCount = 0;

    _checkHandCounts();

    if (player.cardCount == 0) {
      mustChallenge = true;
      lastPlayerToPlayAllCards = player;
    }

    _nextTurn();
  }

  bool passTurn({required Player player}) {
    if (player.id != currentPlayer.id) {
      throw Exception('不是该玩家的回合！');
    }
    
    if (mustChallenge) {
      throw Exception('必须对上一位玩家进行质疑！');
    }

    playersPassedCount++;
    if (playersPassedCount == players.length - 1) {
      playedPile.addAll(lastPlayedCards);
      lastPlayedCards.clear();
      lastCalledRank = '';
      playersPassedCount = 0;
      _nextTurn();
      _checkHandCounts();
      return true;
    }
    _nextTurn();
    _checkHandCounts();
    return false;
  }

  String? challenge({required Player challenger}) {
    Player liar = players[(currentPlayerIndex - 1 + players.length) % players.length];
    
    bool isLiar = false;
    for (var card in lastPlayedCards) {
      if (card.rank.toString().split('.').last.toLowerCase() != lastCalledRank.toLowerCase()) {
        isLiar = true;
        break;
      }
    }
    
    if (mustChallenge) {
      if (!isLiar) {
        return liar.name;
      } else {
        liar.addCards(lastPlayedCards);
        lastPlayedCards.clear();
        lastCalledRank = '';
        currentPlayerIndex = challenger.id;
        mustChallenge = false;
        lastPlayerToPlayAllCards = null;
        playersPassedCount = 0;
        return null;
      }
    }
    
    if (isLiar) {
      liar.addCards(lastPlayedCards);
      lastPlayedCards.clear();
      lastCalledRank = '';
      currentPlayerIndex = challenger.id;
    } else {
      challenger.addCards(lastPlayedCards);
      lastPlayedCards.clear();
      lastCalledRank = '';
      currentPlayerIndex = liar.id;
    }

    playersPassedCount = 0;
    _checkHandCounts();
    return null;
  }
}