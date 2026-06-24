// lib/providers/history_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_result.dart';

const _kHistoryKey = 'pokedmg_history';

class HistoryProvider extends ChangeNotifier {
  List<MatchResult> _history = [];
  bool _loaded = false;

  List<MatchResult> get history => List.unmodifiable(_history..sort((a, b) => b.date.compareTo(a.date)));
  bool get loaded => _loaded;

  int get totalMatches => _history.length;
  int get wins => _history.where((m) => m.isWin).length;
  int get losses => _history.where((m) => !m.isWin).length;

  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (wins / totalMatches) * 100;
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _history = list.map((m) => MatchResult.fromJson(m)).toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryKey, jsonEncode(_history.map((m) => m.toJson()).toList()));
  }

  Future<void> addMatch(MatchResult match) async {
    _history.add(match);
    await _save();
    notifyListeners();
  }

  Future<void> deleteMatch(String id) async {
    _history.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _save();
    notifyListeners();
  }
}
