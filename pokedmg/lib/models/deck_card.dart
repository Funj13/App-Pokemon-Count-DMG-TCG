// lib/models/deck_card.dart

import 'pokemon.dart';
import 'tool_card.dart';

enum DeckCardType { pokemon, tool, energy, trainer }

extension DeckCardTypeExt on DeckCardType {
  String get label {
    switch (this) {
      case DeckCardType.pokemon:  return 'Pokémon';
      case DeckCardType.tool:     return 'Ferramenta';
      case DeckCardType.energy:   return 'Energia';
      case DeckCardType.trainer:  return 'Treinador';
    }
  }

  int get colorValue {
    switch (this) {
      case DeckCardType.pokemon:  return 0xFFE63946;
      case DeckCardType.tool:     return 0xFF78909C;
      case DeckCardType.energy:   return 0xFFFFCA28;
      case DeckCardType.trainer:  return 0xFF42A5F5;
    }
  }

  bool get hasLimit => this != DeckCardType.energy;
  int get maxCopies => hasLimit ? 4 : 999;
}

class DeckCard {
  final String id;
  String name;
  DeckCardType type;
  int quantity;
  String description;
  String? imagePath;

  // Campos de Pokémon
  PokemonType? pokemonType;
  PokemonType? pokemonWeakness;
  int? pokemonHp;
  PokemonStage? pokemonStage;
  String? preEvolutionId; // ID da carta de pré-evolução

  // Campos de Ferramenta
  ToolEffect toolEffect;
  int toolEffectValue; // valor de +HP ou +DMG

  DeckCard({
    required this.id,
    required this.name,
    required this.type,
    this.quantity = 1,
    this.description = '',
    this.imagePath,
    this.pokemonType,
    this.pokemonWeakness,
    this.pokemonHp,
    this.toolEffect = ToolEffect.none,
    this.toolEffectValue = 0,
    this.pokemonStage,
    this.preEvolutionId,
  });

  bool get canAddMore => quantity < type.maxCopies;

  /// Ferramenta pode ser anexada a um Pokémon só se tiver efeito permanente
  bool get isAttachable => type == DeckCardType.tool && toolEffect.canAttach;

  PokemonStage get stage => pokemonStage ?? PokemonStage.basic;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'quantity': quantity,
    'description': description,
    'imagePath': imagePath,
    'pokemonType': pokemonType?.index,
    'pokemonWeakness': pokemonWeakness?.index,
    'pokemonHp': pokemonHp,
    'toolEffect': toolEffect.index,
    'toolEffectValue': toolEffectValue,
    'pokemonStage': pokemonStage?.index,
    'preEvolutionId': preEvolutionId,
  };

  factory DeckCard.fromJson(Map<String, dynamic> j) => DeckCard(
    id: j['id'],
    name: j['name'],
    type: DeckCardType.values[j['type']],
    quantity: j['quantity'] ?? 1,
    description: j['description'] ?? '',
    imagePath: j['imagePath'],
    pokemonType: j['pokemonType'] != null ? PokemonType.values[j['pokemonType']] : null,
    pokemonWeakness: j['pokemonWeakness'] != null ? PokemonType.values[j['pokemonWeakness']] : null,
    pokemonHp: j['pokemonHp'],
    toolEffect: j['toolEffect'] != null ? ToolEffect.values[j['toolEffect']] : ToolEffect.none,
    toolEffectValue: j['toolEffectValue'] ?? 0,
    pokemonStage: j['pokemonStage'] != null ? PokemonStage.values[j['pokemonStage']] : null,
    preEvolutionId: j['preEvolutionId'],
  );
}

class Deck {
  final String id;
  String name;
  String description;
  List<DeckCard> cards;

  Deck({
    required this.id,
    required this.name,
    this.description = '',
    List<DeckCard>? cards,
  }) : cards = cards ?? [];

  static const int maxCards = 60;

  int get totalCards => cards.fold(0, (s, c) => s + c.quantity);
  int get remaining  => maxCards - totalCards;
  bool get isFull    => totalCards >= maxCards;

  List<DeckCard> get pokemonCards  => cards.where((c) => c.type == DeckCardType.pokemon).toList();
  List<DeckCard> get toolCards     => cards.where((c) => c.type == DeckCardType.tool).toList();
  List<DeckCard> get energyCards   => cards.where((c) => c.type == DeckCardType.energy).toList();
  List<DeckCard> get trainerCards  => cards.where((c) => c.type == DeckCardType.trainer).toList();

  /// Somente ferramentas com efeito que podem ser anexadas a Pokémons
  List<DeckCard> get attachableTools => cards.where((c) => c.isAttachable).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cards': cards.map((c) => c.toJson()).toList(),
  };

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
    id: j['id'],
    name: j['name'],
    description: j['description'] ?? '',
    cards: (j['cards'] as List).map((c) => DeckCard.fromJson(c)).toList(),
  );
}
