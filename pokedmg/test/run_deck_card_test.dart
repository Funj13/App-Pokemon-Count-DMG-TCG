// test/run_deck_card_test.dart
import '../lib/models/deck_card.dart';
import '../lib/models/pokemon.dart';

void main() {
  print('--- Running manual unit tests ---');
  try {
    // Test 1: DeckCard JSON serialization preserves preEvolutionId
    final card = DeckCard(
      id: 'charizard-id',
      name: 'Charizard ex',
      type: DeckCardType.pokemon,
      pokemonStage: PokemonStage.stage2,
      preEvolutionId: 'charmeleon-id',
      pokemonHp: 330,
    );

    final json = card.toJson();
    if (json['preEvolutionId'] != 'charmeleon-id') {
      throw Exception('preEvolutionId was not serialized correctly: ${json['preEvolutionId']}');
    }

    final deserialized = DeckCard.fromJson(json);
    if (deserialized.preEvolutionId != 'charmeleon-id') {
      throw Exception('preEvolutionId was not deserialized correctly');
    }
    if (deserialized.stage != PokemonStage.stage2) {
      throw Exception('stage was not deserialized correctly');
    }
    print('Test 1 (serialization) passed!');

    // Test 2: PokemonStage extension canEvolveTo helper logic
    if (PokemonStage.basic.canEvolveTo(PokemonStage.stage1) != true) {
      throw Exception('Basic should evolve to Stage 1');
    }
    if (PokemonStage.stage1.canEvolveTo(PokemonStage.stage2) != true) {
      throw Exception('Stage 1 should evolve to Stage 2');
    }
    if (PokemonStage.basic.canEvolveTo(PokemonStage.stage2) != false) {
      throw Exception('Basic should NOT evolve directly to Stage 2');
    }
    if (PokemonStage.stage2.canEvolveTo(PokemonStage.basic) != false) {
      throw Exception('Stage 2 should NOT evolve to Basic');
    }
    print('Test 2 (canEvolveTo) passed!');

    // Test 3: Pokemon.copyWith deckCardId updates and clears
    final initialPokemon = Pokemon(
      id: 'active-pkmn',
      name: 'Charmander',
      baseMaxHp: 70,
      type: PokemonType.fire,
      stage: PokemonStage.basic,
      deckCardId: 'charmander-card-id',
    );

    // Evolve using a deck card
    final evolvedPokemon = initialPokemon.copyWith(
      name: 'Charmeleon',
      baseMaxHp: 90,
      stage: PokemonStage.stage1,
      deckCardId: 'charmeleon-card-id',
    );
    if (evolvedPokemon.deckCardId != 'charmeleon-card-id') {
      throw Exception('deckCardId should be updated to charmeleon-card-id, but was ${evolvedPokemon.deckCardId}');
    }

    // Evolve manually (should clear deckCardId)
    final manualEvolvedPokemon = evolvedPokemon.copyWith(
      name: 'Charizard ex',
      baseMaxHp: 330,
      stage: PokemonStage.stage2,
      clearDeckCardId: true,
    );
    if (manualEvolvedPokemon.deckCardId != null) {
      throw Exception('deckCardId should be cleared (null) but was ${manualEvolvedPokemon.deckCardId}');
    }
    print('Test 3 (Pokemon.copyWith deckCardId) passed!');

    print('All manual tests passed successfully!');
  } catch (e, stack) {
    print('Test failed: $e');
    print(stack);
    // Exit with non-zero exit code to signal failure
    importDartIoExit(1);
  }
}

void importDartIoExit(int code) {
  // We can't conditionally import easily in a single script, but we can call dart:io's exit via mirrors or just standard dart:io.
  // Let's import dart:io at the top next time if needed, or simply let exception bubble up.
  throw Exception('Test Execution Failure');
}
