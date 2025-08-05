// lib/models/card.dart

enum Suit { clubs, diamonds, hearts, spades, none }

enum Rank {
  two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace, jokerA, jokerB
}

class Card {
  final Suit suit;
  final Rank rank;

  Card(this.suit, this.rank);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}