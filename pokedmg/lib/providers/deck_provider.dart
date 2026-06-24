// lib/providers/deck_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/deck_card.dart';

const _kDecksKey = 'pokedmg_decks';
const _uuid = Uuid();

class DeckProvider extends ChangeNotifier {
  List<Deck> _decks = [];
  bool _loaded = false;

  List<Deck> get decks => List.unmodifiable(_decks);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDecksKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _decks = list.map((d) => Deck.fromJson(d)).toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDecksKey, jsonEncode(_decks.map((d) => d.toJson()).toList()));
  }

  Deck? getDeck(String id) {
    try { return _decks.firstWhere((d) => d.id == id); } catch (_) { return null; }
  }

  Future<Deck> createDeck({required String name, String description = ''}) async {
    final deck = Deck(id: _uuid.v4(), name: name, description: description);
    _decks.add(deck);
    await _save();
    notifyListeners();
    return deck;
  }

  Future<void> updateDeckMeta(String id, {required String name, String description = ''}) async {
    final i = _decks.indexWhere((d) => d.id == id);
    if (i == -1) return;
    _decks[i].name = name;
    _decks[i].description = description;
    await _save();
    notifyListeners();
  }

  Future<void> deleteDeck(String id) async {
    _decks.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
  }

  /// Adiciona ou incrementa quantidade de uma carta
  Future<void> addCard(String deckId, DeckCard card) async {
    final deck = getDeck(deckId);
    if (deck == null) return;

    // Verificar limite 60 cartas
    if (deck.isFull) return;

    // Verificar se já existe (mesmo nome + tipo)
    final existing = deck.cards.where((c) => c.name.toLowerCase() == card.name.toLowerCase() && c.type == card.type).firstOrNull;

    if (existing != null) {
      if (!existing.canAddMore) return;
      final total = deck.remaining;
      existing.quantity = (existing.quantity + 1).clamp(1, existing.quantity + total.clamp(0, 1));
    } else {
      deck.cards.add(card);
    }

    await _save();
    notifyListeners();
  }

  Future<void> setQuantity(String deckId, String cardId, int qty) async {
    final deck = getDeck(deckId);
    if (deck == null) return;
    final card = deck.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;

    final maxQty = card.type.maxCopies;
    final delta = qty - card.quantity;
    if (delta > deck.remaining) return; // excederia 60
    card.quantity = qty.clamp(0, maxQty);
    if (card.quantity == 0) deck.cards.removeWhere((c) => c.id == cardId);
    await _save();
    notifyListeners();
  }

  Future<void> removeCard(String deckId, String cardId) async {
    final deck = getDeck(deckId);
    if (deck == null) return;
    deck.cards.removeWhere((c) => c.id == cardId);
    await _save();
    notifyListeners();
  }

  Future<void> updateCard(String deckId, DeckCard updated) async {
    final deck = getDeck(deckId);
    if (deck == null) return;
    final i = deck.cards.indexWhere((c) => c.id == updated.id);
    if (i == -1) return;
    deck.cards[i] = updated;
    await _save();
    notifyListeners();
  }
}
