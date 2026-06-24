// lib/screens/deck_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/deck_card.dart';
import '../providers/deck_provider.dart';
import '../theme/app_theme.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeckProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('MEUS DECKS')),
      body: !provider.loaded
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : provider.decks.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: provider.decks.length,
                  itemBuilder: (_, i) {
                    final deck = provider.decks[i];
                    return _DeckTile(deck: deck)
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideY(begin: 0.05, duration: 200.ms);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('NOVO DECK', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Novo deck', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do deck'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final deck = await context.read<DeckProvider>().createDeck(
                name: name,
                description: descCtrl.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DeckDetailScreen(deckId: deck.id),
                ));
              }
            },
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  final Deck deck;
  const _DeckTile({required this.deck});

  @override
  Widget build(BuildContext context) {
    final total = deck.totalCards;
    final pct   = total / Deck.maxCards;
    final full  = deck.isFull;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DeckDetailScreen(deckId: deck.id),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: full ? AppTheme.accent.withOpacity(0.5) : AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(deck.name,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: full ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: full ? AppTheme.accent : AppTheme.divider),
                  ),
                  child: Text(
                    '$total / ${Deck.maxCards}',
                    style: TextStyle(
                      color: full ? AppTheme.accent : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (deck.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(deck.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            // Barra de progresso do deck
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(children: [
                Container(height: 6, color: AppTheme.divider),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(height: 6, color: full ? AppTheme.accent : AppTheme.hpGreen),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Contagem por tipo
            Row(
              children: [
                _TypeCount(label: 'PKM', count: deck.pokemonCards.fold(0, (s,c)=>s+c.quantity), color: const Color(0xFFE63946)),
                const SizedBox(width: 8),
                _TypeCount(label: 'FERR', count: deck.toolCards.fold(0, (s,c)=>s+c.quantity), color: const Color(0xFF78909C)),
                const SizedBox(width: 8),
                _TypeCount(label: 'ENER', count: deck.energyCards.fold(0, (s,c)=>s+c.quantity), color: const Color(0xFFFFCA28)),
                const SizedBox(width: 8),
                _TypeCount(label: 'TREI', count: deck.trainerCards.fold(0, (s,c)=>s+c.quantity), color: const Color(0xFF42A5F5)),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.5), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TypeCount({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.style_outlined, size: 72, color: AppTheme.accent.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text('Nenhum deck criado', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Text('Crie seu primeiro deck para começar', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ).animate().fadeIn(duration: 400.ms),
  );
}
