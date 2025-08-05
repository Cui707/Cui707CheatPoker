// lib/models/game.dart

import 'package:cui707cheatpoker/models/card.dart';
import 'dart:math';

class Player {
  final int id;
  final String name;
  List<Card> hand = [];

  Player({required this.id, required this.name});

  int get cardCount => hand.length;

  void addCards(List<Card> cards) {
    hand.addAll(cards);
  }

  void removeCards(List<Card> cards) {
    for (var card in cards) {
      hand.remove(card);
    }
  }

  bool hasCards(List<Card> cards) {
    for (var card in cards) {
      if (!hand.contains(card)) {
        return false;
      }
    }
    return true;
  }
}

class Game {
  late List<Player> players;
  late List<Card> deck;
  List<Card> playedPile = [];
  List<Card> lastPlayedCards = [];
  Rank? lastCalledRank;
  int currentPlayerIndex = 0;
  int playersPassedCount = 0;
  
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
    lastCalledRank = null;
    mustChallenge = false;
    lastPlayerToPlayAllCards = null;
  }

  List<Card> _createDeck() {
    List<Card> newDeck = [];
    for (var suit in Suit.values) {
      if (suit == Suit.none) continue;
      for (var rank in Rank.values) {
        if (rank == Rank.jokerA || rank == Rank.jokerB) continue;
        newDeck.add(Card(suit, rank));
      }
    }
    // 添加大小王
    newDeck.add(Card(Suit.none, Rank.jokerA));
    newDeck.add(Card(Suit.none, Rank.jokerB));
    
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
    
    lastPlayedCards.clear();
    lastPlayedCards.addAll(cardsToPlay);
    lastCalledRank = calledRank;
    playersPassedCount = 0;

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
      lastCalledRank = null;
      playersPassedCount = 0;
      _nextTurn();
      return true;
    }
    _nextTurn();
    return false;
  }

  String? challenge({required Player challenger}) {
    Player liar = players[(currentPlayerIndex - 1 + players.length) % players.length];
    
    bool isLiar = false;
    for (var card in lastPlayedCards) {
      if (card.rank != lastCalledRank) {
        isLiar = true;
        break;
      }
    }
    
    if (mustChallenge) {
      if (isLiar) {
        // 质疑成功，出牌者是骗子，拿走所有牌
        liar.addCards(playedPile);
        liar.addCards(lastPlayedCards);
        playedPile.clear();
        lastPlayedCards.clear();
        lastCalledRank = null;
        currentPlayerIndex = challenger.id;
        mustChallenge = false;
        lastPlayerToPlayAllCards = null;
        playersPassedCount = 0;
        return null;
      } else {
        // 质疑失败，出牌者是赢家
        return liar.name;
      }
    }
    
    if (isLiar) {
      // 质疑成功
      liar.addCards(playedPile);
      liar.addCards(lastPlayedCards);
      lastPlayedCards.clear();
      playedPile.clear();
      lastCalledRank = null;
      currentPlayerIndex = challenger.id;
    } else {
      // 质疑失败
      challenger.addCards(playedPile);
      challenger.addCards(lastPlayedCards);
      lastPlayedCards.clear();
      playedPile.clear();
      lastCalledRank = null;
      currentPlayerIndex = liar.id;
    }

    playersPassedCount = 0;
    return null;
  }
}