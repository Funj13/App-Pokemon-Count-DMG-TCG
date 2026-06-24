import 'package:flutter_test/flutter_test.dart';
import 'package:pokedmg/models/deck_card.dart';
import 'package:pokedmg/models/pokemon.dart';

void main() {
  group('DeckCard Pre-Evolution Tests', () {
    test('DeckCard JSON serialization preserves preEvolutionId', () {
      final card = DeckCard(
        id: 'charizard-id',
        name: 'Charizard ex',
        type: DeckCardType.pokemon,
        pokemonStage: PokemonStage.stage2,
        preEvolutionId: 'charmeleon-id',
        pokemonHp: 330,
      );

      final json = card.toJson();
      expect(json['preEvolutionId'], 'charmeleon-id');

      final deserialized = DeckCard.fromJson(json);
      expect(deserialized.preEvolutionId, 'charmeleon-id');
      expect(deserialized.stage, PokemonStage.stage2);
    });

    test('PokemonStage extension canEvolveTo helper logic', () {
      expect(PokemonStage.basic.canEvolveTo(PokemonStage.stage1), isTrue);
      expect(PokemonStage.stage1.canEvolveTo(PokemonStage.stage2), isTrue);
      expect(PokemonStage.basic.canEvolveTo(PokemonStage.stage2), isFalse);
      expect(PokemonStage.stage2.canEvolveTo(PokemonStage.basic), isFalse);
    });
  });
}
