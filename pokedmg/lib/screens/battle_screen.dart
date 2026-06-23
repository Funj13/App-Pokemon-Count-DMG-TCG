// lib/screens/battle_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/add_pokemon_sheet.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('POKEDMG TCG'),
        actions: [
          // Damage step selector
          PopupMenuButton<int>(
            color: AppTheme.surface,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 16, color: AppTheme.accent),
                const SizedBox(width: 4),
                Text(
                  '${provider.damageStep}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            tooltip: 'Passo de dano',
            onSelected: provider.setDamageStep,
            itemBuilder: (_) => [10, 20, 30, 40, 50, 60, 80, 100, 120]
                .map((v) => PopupMenuItem(
                      value: v,
                      child: Text(
                        '$v',
                        style: TextStyle(
                          color: v == provider.damageStep ? AppTheme.accent : AppTheme.textPrimary,
                          fontWeight: v == provider.damageStep ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Resetar HP de todos',
            onPressed: provider.pokemons.isEmpty
                ? null
                : () => _confirmReset(context, provider),
          ),
        ],
      ),
      body: provider.pokemons.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.pokemons.length,
              itemBuilder: (_, i) {
                final pokemon = provider.pokemons[i];
                return PokemonCard(key: ValueKey(pokemon.id), pokemon: pokemon)
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.1, duration: 250.ms, curve: Curves.easeOut);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'POKÉMON',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddPokemonSheet(),
    );
  }

  void _confirmReset(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Resetar batalha?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'O HP de todos os Pokémons será restaurado ao máximo.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetAll();
              Navigator.pop(context);
            },
            child: const Text('Resetar'),
          ),
        ],
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
          Icon(
            Icons.catching_pokemon,
            size: 72,
            color: AppTheme.accent.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum Pokémon na batalha',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus Pokémons para começar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), duration: 400.ms),
    );
  }
}
