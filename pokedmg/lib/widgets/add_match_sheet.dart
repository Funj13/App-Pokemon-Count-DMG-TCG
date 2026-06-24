// lib/widgets/add_match_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/match_result.dart';
import '../providers/deck_provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';

class AddMatchSheet extends StatefulWidget {
  final String? initialDeckId;
  final String? initialDeckName;
  final int? initialMyKnockouts;
  final int? initialOpponentKnockouts;

  const AddMatchSheet({
    super.key,
    this.initialDeckId,
    this.initialDeckName,
    this.initialMyKnockouts,
    this.initialOpponentKnockouts,
  });

  @override
  State<AddMatchSheet> createState() => _AddMatchSheetState();
}

class _AddMatchSheetState extends State<AddMatchSheet> {
  final _uuid = const Uuid();
  final _opponentNameController = TextEditingController();
  final _opponentDeckController = TextEditingController();
  final _customDeckNameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDeckId;
  bool _isCustomDeck = true;
  bool _isWin = true;
  int _myKnockouts = 0;
  int _opponentKnockouts = 0;

  @override
  void initState() {
    super.initState();
    _myKnockouts = widget.initialMyKnockouts ?? 0;
    _opponentKnockouts = widget.initialOpponentKnockouts ?? 0;
    if (widget.initialDeckId != null) {
      _selectedDeckId = widget.initialDeckId;
      _isCustomDeck = false;
    } else if (widget.initialDeckName != null) {
      _customDeckNameController.text = widget.initialDeckName!;
      _isCustomDeck = true;
    }
  }

  @override
  void dispose() {
    _opponentNameController.dispose();
    _opponentDeckController.dispose();
    _customDeckNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final opponentName = _opponentNameController.text.trim();
    final opponentDeck = _opponentDeckController.text.trim();
    final deckProvider = context.read<DeckProvider>();

    String finalDeckName = 'Personalizado';
    String? finalDeckId;

    if (!_isCustomDeck && _selectedDeckId != null) {
      final deck = deckProvider.getDeck(_selectedDeckId!);
      if (deck != null) {
        finalDeckName = deck.name;
        finalDeckId = deck.id;
      }
    } else {
      final customName = _customDeckNameController.text.trim();
      if (customName.isNotEmpty) {
        finalDeckName = customName;
      }
    }

    if (opponentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome do oponente.')),
      );
      return;
    }

    final match = MatchResult(
      id: _uuid.v4(),
      deckId: finalDeckId,
      deckName: finalDeckName,
      opponentName: opponentName,
      opponentDeck: opponentDeck.isNotEmpty ? opponentDeck : 'Não informado',
      isWin: _isWin,
      myKnockouts: _myKnockouts,
      opponentKnockouts: _opponentKnockouts,
      date: DateTime.now(),
      notes: _notesController.text.trim(),
    );

    context.read<HistoryProvider>().addMatch(match);
    Navigator.pop(context, true); // Returns true to signify match was saved
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final decks = deckProvider.decks;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'REGISTRAR PARTIDA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Seleção de Deck ---
            const _SectionLabel(label: 'SEU DECK'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.surface,
                    value: _isCustomDeck ? null : _selectedDeckId,
                    decoration: const InputDecoration(
                      labelText: 'Selecionar Deck',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Personalizado / Digitar nome'),
                      ),
                      ...decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null) {
                          _isCustomDeck = true;
                          _selectedDeckId = null;
                        } else {
                          _isCustomDeck = false;
                          _selectedDeckId = val;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_isCustomDeck) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customDeckNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do seu deck personalizado',
                  hintText: 'Ex: Charizard ex',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 14),

            // --- Dados do Oponente ---
            const _SectionLabel(label: 'OPONENTE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _opponentNameController,
                    decoration: const InputDecoration(labelText: 'Nome do Oponente'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _opponentDeckController,
                    decoration: const InputDecoration(labelText: 'Deck do Oponente', hintText: 'Ex: Lugia VSTAR'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Resultado (Win/Loss) ---
            const _SectionLabel(label: 'RESULTADO'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWin = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isWin ? AppTheme.hpGreen.withOpacity(0.15) : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isWin ? AppTheme.hpGreen : AppTheme.divider,
                          width: _isWin ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: _isWin ? AppTheme.hpGreen : AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'VITÓRIA',
                            style: TextStyle(
                              color: _isWin ? AppTheme.hpGreen : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWin = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isWin ? AppTheme.hpRed.withOpacity(0.15) : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_isWin ? AppTheme.hpRed : AppTheme.divider,
                          width: !_isWin ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, color: !_isWin ? AppTheme.hpRed : AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'DERROTA',
                            style: TextStyle(
                              color: !_isWin ? AppTheme.hpRed : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Placar de Prêmios/Nocautes ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'SEUS PRÊMIOS'),
                      const SizedBox(height: 8),
                      _PrizeSelector(
                        selected: _myKnockouts,
                        color: AppTheme.hpGreen,
                        onSelect: (val) => setState(() => _myKnockouts = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'PRÊMIOS OPONENTE'),
                      const SizedBox(height: 8),
                      _PrizeSelector(
                        selected: _opponentKnockouts,
                        color: AppTheme.hpRed,
                        onSelect: (val) => setState(() => _opponentKnockouts = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Observações ---
            const _SectionLabel(label: 'NOTAS / OBSERVAÇÕES'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Anotações sobre a partida (ex: jogadas importantes, azar, etc.)',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // --- Confirm Button ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('SALVAR PARTIDA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
    );
  }
}

class _PrizeSelector extends StatelessWidget {
  final int selected;
  final Color color;
  final ValueChanged<int> onSelect;

  const _PrizeSelector({
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final isSel = selected == index;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 5),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSel ? color : AppTheme.surfaceCard,
                border: Border.all(
                  color: isSel ? color : AppTheme.divider,
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
