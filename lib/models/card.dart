// lib/models/card.dart

enum Suit { clubs, diamonds, hearts, spades }

enum Rank { two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace }

class Card {
  final Suit suit;
  final Rank rank;

  const Card(this.suit, this.rank);
}