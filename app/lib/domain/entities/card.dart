enum Suit { hearts, diamonds, clubs, spades }

Suit suitFromWire(String value) => Suit.values.firstWhere((s) => s.name == value);

extension SuitDisplay on Suit {
  String get symbol => switch (this) {
        Suit.hearts => '♥',
        Suit.diamonds => '♦',
        Suit.clubs => '♣',
        Suit.spades => '♠',
      };

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

class GameCard {
  final Suit suit;
  final int rank; // 6..14, where 11=J, 12=Q, 13=K, 14=A

  const GameCard({required this.suit, required this.rank});

  factory GameCard.fromJson(Map<String, dynamic> json) =>
      GameCard(suit: suitFromWire(json['suit'] as String), rank: json['rank'] as int);

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank};

  String get rankLabel => switch (rank) {
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        14 => 'A',
        _ => rank.toString(),
      };

  @override
  bool operator ==(Object other) => other is GameCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '$rankLabel${suit.symbol}';
}
