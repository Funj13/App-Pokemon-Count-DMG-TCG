// lib/models/match_result.dart

class MatchResult {
  final String id;
  final String? deckId;
  final String deckName;
  final String opponentName;
  final String opponentDeck;
  final bool isWin;
  final int myKnockouts;
  final int opponentKnockouts;
  final DateTime date;
  final String notes;

  MatchResult({
    required this.id,
    this.deckId,
    required this.deckName,
    required this.opponentName,
    required this.opponentDeck,
    required this.isWin,
    required this.myKnockouts,
    required this.opponentKnockouts,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'deckName': deckName,
    'opponentName': opponentName,
    'opponentDeck': opponentDeck,
    'isWin': isWin,
    'myKnockouts': myKnockouts,
    'opponentKnockouts': opponentKnockouts,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory MatchResult.fromJson(Map<String, dynamic> j) => MatchResult(
    id: j['id'],
    deckId: j['deckId'],
    deckName: j['deckName'] ?? 'Personalizado',
    opponentName: j['opponentName'] ?? '',
    opponentDeck: j['opponentDeck'] ?? '',
    isWin: j['isWin'] ?? false,
    myKnockouts: j['myKnockouts'] ?? 0,
    opponentKnockouts: j['opponentKnockouts'] ?? 0,
    date: DateTime.parse(j['date']),
    notes: j['notes'] ?? '',
  );
}
