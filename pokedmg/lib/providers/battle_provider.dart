// lib/providers/battle_provider.dart

import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';

class BattleProvider extends ChangeNotifier {
  final List<Pokemon> _pokemons = [];
  int _damageStep = 10;

  List<Pokemon> get pokemons => List.unmodifiable(_pokemons);
  int get damageStep => _damageStep;
  bool get hasFainted => _pokemons.any((p) => p.isFainted);

  void addPokemon(Pokemon pokemon) {
    _pokemons.add(pokemon);
    notifyListeners();
  }

  void removePokemon(String id) {
    _pokemons.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void applyDamage(String id, int amount) {
    final index = _pokemons.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final p = _pokemons[index];
    final newHp = (p.currentHp - amount).clamp(0, p.maxHp);
    _pokemons[index] = p.copyWith(currentHp: newHp);
    notifyListeners();
  }

  void healPokemon(String id, int amount) {
    final index = _pokemons.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final p = _pokemons[index];
    final newHp = (p.currentHp + amount).clamp(0, p.maxHp);
    _pokemons[index] = p.copyWith(currentHp: newHp);
    notifyListeners();
  }

  void fullHeal(String id) {
    final index = _pokemons.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final p = _pokemons[index];
    _pokemons[index] = p.copyWith(currentHp: p.maxHp);
    notifyListeners();
  }

  void setDamageStep(int step) {
    _damageStep = step;
    notifyListeners();
  }

  void resetAll() {
    for (int i = 0; i < _pokemons.length; i++) {
      final p = _pokemons[i];
      _pokemons[i] = p.copyWith(currentHp: p.maxHp);
    }
    notifyListeners();
  }
}
