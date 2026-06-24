// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/match_result.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_match_sheet.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final matches = provider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTÓRICO'),
        actions: [
          if (matches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppTheme.hpRed),
              tooltip: 'Limpar tudo',
              onPressed: () => _confirmClear(context, provider),
            ),
        ],
      ),
      body: provider.totalMatches == 0
          ? const _EmptyState()
          : Column(
              children: [
                _StatsDashboard(provider: provider),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _MatchCard(
                        match: match,
                        formattedDate: _formatDate(match.date),
                        onDelete: () => _confirmDeleteMatch(context, provider, match),
                      ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1, duration: 300.ms);
                    },
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
          builder: (_) => const AddMatchSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('PARTIDA', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }

  void _confirmDeleteMatch(BuildContext context, HistoryProvider provider, MatchResult match) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir partida?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Deseja mesmo excluir o registro contra ${match.opponentName}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteMatch(match.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hpRed),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Limpar todo o histórico?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Esta ação não pode ser desfeita. Todos os registros serão apagados.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hpRed),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  final HistoryProvider provider;
  const _StatsDashboard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final winColor = AppTheme.hpGreen;
    final lossColor = AppTheme.hpRed;
    final rate = provider.winRate;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Aproveitamento
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APROVEITAMENTO',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: rate >= 50.0 ? winColor : (rate > 0.0 ? AppTheme.hpYellow : AppTheme.textPrimary),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 50.0 ? winColor : (rate > 0.0 ? AppTheme.hpYellow : AppTheme.hpRed),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 60, color: AppTheme.divider),
          const SizedBox(width: 20),
          // Indicadores numéricos
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'VITÓRIAS', value: '${provider.wins}', color: winColor),
                _StatItem(label: 'DERROTAS', value: '${provider.losses}', color: lossColor),
                _StatItem(label: 'TOTAL', value: '${provider.totalMatches}', color: AppTheme.textPrimary),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.9, duration: 400.ms);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchResult match;
  final String formattedDate;
  final VoidCallback onDelete;

  const _MatchCard({
    required this.match,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = match.isWin ? AppTheme.hpGreen : AppTheme.hpRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Partida
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                // Win/Loss Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    match.isWin ? 'VITÓRIA' : 'DERROTAS', // Note: Using matches terminology
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 16),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Corpo da partida
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deck do Jogador
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SEU DECK', style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(
                            match.deckName,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Placar Central
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const Text('PLACAR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Text(
                              '${match.myKnockouts} - ${match.opponentKnockouts}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Oponente
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('VS ${match.opponentName.toUpperCase()}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(
                            match.opponentDeck,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Notas/Observações se houver
                if (match.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            match.notes,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 72, color: AppTheme.accent.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Sem histórico de partidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus resultados de partidas de TCG aparecerão aqui após registrá-las manualmente ou ao finalizar uma batalha.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }
}
