// lib/providers/battle_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';
import '../models/tool_card.dart';

const _kBattlePokemonsKey = 'pokedmg_battle_pokemons';
const _kBattleTurnKey = 'pokedmg_battle_turn';

class BattleProvider extends ChangeNotifier {
  final List<Pokemon> _pokemons = [];
  int _turn = 1;
  bool _loaded = false;

  List<Pokemon> get pokemons => List.unmodifiable(_pokemons);
  List<Pokemon> get activePokemons => _pokemons.where((p) => p.isActive).toList();
  List<Pokemon> get benchPokemons  => _pokemons.where((p) => !p.isActive).toList();
  int get turn => _turn;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawPokemons = prefs.getString(_kBattlePokemonsKey);
    if (rawPokemons != null) {
      final list = jsonDecode(rawPokemons) as List;
      _pokemons.clear();
      _pokemons.addAll(list.map((p) => Pokemon.fromJson(p)));
    }
    _turn = prefs.getInt(_kBattleTurnKey) ?? 1;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBattlePokemonsKey, jsonEncode(_pokemons.map((p) => p.toJson()).toList()));
    await prefs.setInt(_kBattleTurnKey, _turn);
  }

  Future<void> nextTurn() async {
    _turn++;
    await _save();
    notifyListeners();
  }

  Future<void> resetTurn() async {
    _turn = 1;
    await _save();
    notifyListeners();
  }

  Future<void> addPokemon(Pokemon pokemon) async {
    _pokemons.add(pokemon);
    await _save();
    notifyListeners();
  }

  Future<void> removePokemon(String id) async {
    _pokemons.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> updatePokemon(String id, Pokemon updated) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final oldPokemon = _pokemons[i];
    final oldDamage = (oldPokemon.maxHp - oldPokemon.currentHp).clamp(0, oldPokemon.maxHp);

    final newMaxHp = updated.maxHp;
    final newCurrentHp = (newMaxHp - oldDamage).clamp(0, newMaxHp);

    _pokemons[i] = updated.copyWith(currentHp: newCurrentHp);
    await _save();
    notifyListeners();
  }

  Future<void> evolvePokemon(
    String id, {
    required String name,
    required int baseMaxHp,
    required PokemonType type,
    required PokemonType weakness,
    required PokemonStage stage,
    String? imagePath,
    String? deckCardId,
    bool clearDeckCardId = false,
  }) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final oldPokemon = _pokemons[i];
    final oldDamage = (oldPokemon.maxHp - oldPokemon.currentHp).clamp(0, oldPokemon.maxHp);

    var newPokemon = oldPokemon.copyWith(
      name: name,
      baseMaxHp: baseMaxHp,
      type: type,
      weakness: weakness,
      imagePath: imagePath,
      clearImage: imagePath == null,
      stage: stage,
      deckCardId: deckCardId,
      clearDeckCardId: clearDeckCardId,
    );

    final newCurrentHp = (newPokemon.maxHp - oldDamage).clamp(0, newPokemon.maxHp);
    newPokemon = newPokemon.copyWith(currentHp: newCurrentHp);

    _pokemons[i] = newPokemon;
    await _save();
    notifyListeners();
  }

  Future<void> setPosition(String id, PokemonPosition pos) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _pokemons[i] = _pokemons[i].copyWith(position: pos);
    await _save();
    notifyListeners();
  }

  Future<void> applyDamage(String id, int amount) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final p = _pokemons[i];
    final newHp = (p.currentHp - amount).clamp(0, p.maxHp);
    _pokemons[i] = p.copyWith(currentHp: newHp);
    await _save();
    notifyListeners();
  }

  Future<void> applyWeaknessDamage(String id, int amount) => applyDamage(id, amount * 2);

  Future<void> healPokemon(String id, int amount) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final p = _pokemons[i];
    final newHp = (p.currentHp + amount).clamp(0, p.maxHp);
    _pokemons[i] = p.copyWith(currentHp: newHp);
    await _save();
    notifyListeners();
  }

  Future<void> fullHeal(String id) async {
    final i = _pokemons.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final p = _pokemons[i];
    _pokemons[i] = p.copyWith(currentHp: p.maxHp);
    await _save();
    notifyListeners();
  }

  Future<void> addTool(String pokemonId, ToolCard tool) async {
    final i = _pokemons.indexWhere((p) => p.id == pokemonId);
    if (i == -1) return;
    _pokemons[i].addTool(tool);
    await _save();
    notifyListeners();
  }

  Future<void> removeTool(String pokemonId, String toolId) async {
    final i = _pokemons.indexWhere((p) => p.id == pokemonId);
    if (i == -1) return;
    _pokemons[i].removeTool(toolId);
    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    for (int i = 0; i < _pokemons.length; i++) {
      _pokemons[i] = _pokemons[i].copyWith(currentHp: _pokemons[i].maxHp);
    }
    await _save();
    notifyListeners();
  }
}
