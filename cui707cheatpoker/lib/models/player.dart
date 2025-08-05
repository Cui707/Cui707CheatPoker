// lib/models/player.dart

import 'package:cui707cheatpoker/models/card.dart';

class Player {
  final int id;
  final String name;
  List<Card> hand;

  Player({required this.id, required this.name, List<Card>? initialHand})
      : hand = initialHand ?? [];

  int get cardCount => hand.length;

  void addCards(List<Card> cards) {
    hand.addAll(cards);
  }

  void removeCards(List<Card> cards) {
    for (var card in cards) {
      hand.removeWhere((c) => c.suit == card.suit && c.rank == card.rank);
    }
  }

  // 修复: 添加 hasCards 方法
  bool hasCards(List<Card> cards) {
    final handCopy = List<Card>.from(hand);
    for (var card in cards) {
      bool found = false;
      for (var handCard in handCopy) {
        if (handCard.suit == card.suit && handCard.rank == card.rank) {
          handCopy.remove(handCard);
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
    return true;
  }
}