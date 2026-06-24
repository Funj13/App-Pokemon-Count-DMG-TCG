// lib/widgets/evolve_pokemon_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/deck_card.dart';
import '../models/pokemon.dart';
import '../providers/battle_provider.dart';
import '../providers/deck_provider.dart';
import '../theme/app_theme.dart';

class EvolvePokemonSheet extends StatefulWidget {
  final Pokemon pokemon;
  final BattleProvider provider;

  const EvolvePokemonSheet({
    super.key,
    required this.pokemon,
    required this.provider,
  });

  @override
  State<EvolvePokemonSheet> createState() => _EvolvePokemonSheetState();
}

class _EvolvePokemonSheetState extends State<EvolvePokemonSheet> {
  int _tab = 0; // 0: Do Deck, 1: Manual

  PokemonStage get nextStage => widget.pokemon.stage == PokemonStage.basic ? PokemonStage.stage1 : PokemonStage.stage2;

  // Tab 0: Deck Selection
  String? _selectedDeckId;

  // Tab 1: Manual Input
  final _nameController = TextEditingController();
  final _hpController = TextEditingController();
  PokemonType _type = PokemonType.fire;
  PokemonType _weakness = PokemonType.water;
  String? _imagePath;
  bool _weaknessEdited = false;

  @override
  void initState() {
    super.initState();
    _type = widget.pokemon.type;
    _weakness = widget.pokemon.weakness;
    // Sugere o próximo HP padrão de evolução baseando-se no HP atual
    _hpController.text = (widget.pokemon.baseMaxHp + 20).toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  void _onTypeChanged(PokemonType t) => setState(() {
        _type = t;
        if (!_weaknessEdited) _weakness = t.defaultWeakness;
      });

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submitDeckEvolution(DeckCard card) async {
    final damage = widget.pokemon.maxHp - widget.pokemon.currentHp;
    await widget.provider.evolvePokemon(
      widget.pokemon.id,
      name: card.name,
      baseMaxHp: card.pokemonHp ?? 100,
      type: card.pokemonType ?? PokemonType.normal,
      weakness: card.pokemonWeakness ?? (card.pokemonType ?? PokemonType.normal).defaultWeakness,
      imagePath: card.imagePath,
      stage: nextStage,
      deckCardId: card.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.pokemon.name} evoluiu para ${card.name}! Dano de $damage HP mantido.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _submitManualEvolution() async {
    final name = _nameController.text.trim();
    final hp = int.tryParse(_hpController.text);

    if (name.isEmpty || hp == null || hp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe um nome e HP válido.')),
      );
      return;
    }

    final damage = widget.pokemon.maxHp - widget.pokemon.currentHp;
    await widget.provider.evolvePokemon(
      widget.pokemon.id,
      name: name,
      baseMaxHp: hp,
      type: _type,
      weakness: _weakness,
      imagePath: _imagePath,
      stage: nextStage,
      clearDeckCardId: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.pokemon.name} evoluiu para $name! Dano de $damage HP mantido.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final decks = deckProvider.decks;
    final damage = widget.pokemon.maxHp - widget.pokemon.currentHp;

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

            // Header info
            Row(
              children: [
                const Icon(Icons.upgrade, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  'EVOLUIR POKÉMON',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                        children: [
                          const TextSpan(text: 'Evoluindo '),
                          TextSpan(
                            text: widget.pokemon.name,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' (${widget.pokemon.currentHp}/${widget.pokemon.maxHp} HP).\n'),
                          const TextSpan(text: 'O acumulado de '),
                          TextSpan(
                            text: '$damage de Dano',
                            style: const TextStyle(color: AppTheme.hpRed, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' será mantido após a evolução.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs Selector
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    title: 'ESCOLHER DO DECK',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    title: 'EVOLUÇÃO MANUAL',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (_tab == 0) ...[
              // --- ESCOLHER DO DECK ---
              if (decks.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.style_outlined, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum deck cadastrado',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cadastre seus decks na aba Decks para evoluir seus Pokémons com um clique.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _selectedDeckId,
                  dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(labelText: 'Selecione o Deck'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (id) => setState(() {
                    _selectedDeckId = id;
                  }),
                ),
                if (_selectedDeckId != null) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (_) {
                    final deck = deckProvider.getDeck(_selectedDeckId!);
                    List<DeckCard> pkmnCards = [];
                    bool isDirectEvolution = false;
                    if (deck != null) {
                      final allPkmn = deck.pokemonCards;
                      if (widget.pokemon.deckCardId != null) {
                        pkmnCards = allPkmn.where((c) => c.preEvolutionId == widget.pokemon.deckCardId).toList();
                        if (pkmnCards.isNotEmpty) {
                          isDirectEvolution = true;
                        }
                      }
                      if (pkmnCards.isEmpty) {
                        pkmnCards = allPkmn.where((c) => c.stage == nextStage).toList();
                      }
                    }

                    if (pkmnCards.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhuma carta de ${nextStage.label} cadastrada neste deck.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDirectEvolution) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Text(
                              'EVOLUÇÕES DIRETAS VINCULADAS',
                              style: TextStyle(color: AppTheme.hpYellow, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                        ...pkmnCards.map((card) {
                          final typeColor = card.pokemonType != null ? Color(card.pokemonType!.colorValue) : AppTheme.accent;
                          return GestureDetector(
                            onTap: () => _submitDeckEvolution(card),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Row(
                                children: [
                                  if (card.imagePath != null)
                                    Container(
                                      width: 28,
                                      height: 38,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.file(File(card.imagePath!), fit: BoxFit.cover),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card.name,
                                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (card.pokemonType != null)
                                          Text(
                                            '${card.pokemonType!.label} · ${card.pokemonHp ?? "??"} HP',
                                            style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ],
            ] else ...[
              // --- EVOLUÇÃO MANUAL ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _imagePath != null ? Color(_type.colorValue).withOpacity(0.6) : AppTheme.divider,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null
                        ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Nova foto',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_imagePath != null)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.delete_outline, size: 12, color: AppTheme.textSecondary),
                    label: const Text('Remover foto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ),
                ),
              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Evolução'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hpController,
                decoration: const InputDecoration(labelText: 'HP Máximo da Evolução'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              const _SectionLabel(label: 'ESTÁGIO DA EVOLUÇÃO'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  nextStage.label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Tipo
              const _SectionLabel(label: 'TIPO DA EVOLUÇÃO'),
              const SizedBox(height: 8),
              _TypeGrid(selected: _type, onSelect: _onTypeChanged),
              const SizedBox(height: 14),

              // Fraqueza
              Row(
                children: [
                  const _SectionLabel(label: 'FRAQUEZA'),
                  const SizedBox(width: 6),
                  Text('(automática · toque para editar)', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              _TypeGrid(
                selected: _weakness,
                onSelect: (t) => setState(() {
                  _weakness = t;
                  _weaknessEdited = true;
                }),
                highlightColor: AppTheme.hpRed,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _submitManualEvolution,
                  child: const Text('EVOLUIR POKÉMON'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withOpacity(0.12) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppTheme.accent : AppTheme.divider,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: active ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
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

class _TypeGrid extends StatelessWidget {
  final PokemonType selected;
  final void Function(PokemonType) onSelect;
  final Color? highlightColor;

  const _TypeGrid({
    required this.selected,
    required this.onSelect,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: PokemonType.values.map((type) {
        final color = Color(type.colorValue);
        final accent = highlightColor ?? color;
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.25) : color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? accent : color.withOpacity(0.3), width: isSelected ? 1.5 : 1),
            ),
            child: Text(
              type.label,
              style: TextStyle(
                color: isSelected ? (highlightColor ?? color) : color.withOpacity(0.7),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
