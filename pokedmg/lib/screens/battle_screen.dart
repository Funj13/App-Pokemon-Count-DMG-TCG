// lib/screens/battle_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/add_pokemon_sheet.dart';
import '../widgets/add_match_sheet.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();
    final active = provider.activePokemons;
    final bench  = provider.benchPokemons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POKEDMG TCG'),
        actions: [
          if (provider.pokemons.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined, color: AppTheme.accent),
              tooltip: 'Finalizar Partida',
              onPressed: () => _finalizeMatch(context, provider),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Resetar HP de todos',
            onPressed: provider.pokemons.isEmpty ? null : () => _confirmReset(context, provider),
          ),
        ],
      ),
      body: provider.pokemons.isEmpty
          ? _EmptyState()
          : Column(
              children: [
                // ── Turno counter ──
                _TurnBanner(turn: provider.turn, onNext: provider.nextTurn, onReset: provider.resetTurn),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100, top: 4),
                    children: [
                      // ── ATIVO ──
                      _SectionHeader(
                        label: '⚔  POKÉMON ATIVO',
                        color: AppTheme.accent,
                        count: active.length,
                      ),
                      if (active.isEmpty)
                        _EmptySection(label: 'Nenhum Pokémon ativo no campo')
                      else
                        ...active.map((p) => PokemonCard(key: ValueKey(p.id), pokemon: p)
                            .animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, duration: 200.ms)),

                      const SizedBox(height: 10),

                      // ── BANCO ──
                      _SectionHeader(
                        label: '🪑  BANCO',
                        color: AppTheme.textSecondary,
                        count: bench.length,
                      ),
                      if (bench.isEmpty)
                        _EmptySection(label: 'Nenhum Pokémon no banco')
                      else
                        ...bench.map((p) => PokemonCard(key: ValueKey(p.id), pokemon: p)
                            .animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, duration: 200.ms)),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const AddPokemonSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('POKÉMON', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }

  void _confirmReset(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Resetar batalha?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('O HP de todos os Pokémons será restaurado e o turno voltará para 1.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              provider.resetAll();
              provider.resetTurn();
              Navigator.pop(context);
            },
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
  }

  void _finalizeMatch(BuildContext context, BattleProvider provider) async {
    final opponentKnockouts = provider.pokemons.where((p) => p.isFainted).length;
    
    String? suggestedDeckName;
    if (provider.pokemons.isNotEmpty) {
      suggestedDeckName = provider.pokemons.first.name;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddMatchSheet(
        initialDeckName: suggestedDeckName,
        initialOpponentKnockouts: opponentKnockouts,
        initialMyKnockouts: opponentKnockouts == 0 ? 6 : 0,
      ),
    );

    if (saved == true) {
      await provider.resetAll();
      await provider.resetTurn();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partida registrada! Batalha resetada para o Turno 1.')),
        );
      }
    }
  }
}

class _TurnBanner extends StatelessWidget {
  final int turn;
  final VoidCallback onNext;
  final VoidCallback onReset;
  const _TurnBanner({required this.turn, required this.onNext, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TURNO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Text(
                '$turn',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, height: 1),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onReset,
            child: const Text('REINICIAR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: const Text('PRÓXIMO TURNO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _SectionHeader({required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
        ),
        child: Center(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.catching_pokemon, size: 72, color: AppTheme.accent.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Nenhum Pokémon na batalha', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Adicione seus Pokémons para começar', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), duration: 400.ms),
    );
  }
}
