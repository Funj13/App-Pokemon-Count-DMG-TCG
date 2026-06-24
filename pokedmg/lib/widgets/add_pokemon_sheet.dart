// lib/widgets/add_pokemon_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/deck_card.dart';
import '../models/pokemon.dart';
import '../providers/battle_provider.dart';
import '../providers/deck_provider.dart';
import '../theme/app_theme.dart';

class AddPokemonSheet extends StatefulWidget {
  final Pokemon? existing;
  const AddPokemonSheet({super.key, this.existing});
  @override
  State<AddPokemonSheet> createState() => _AddPokemonSheetState();
}

class _AddPokemonSheetState extends State<AddPokemonSheet> {
  final _nameController = TextEditingController();
  final _hpController   = TextEditingController(text: '120');
  PokemonType _type         = PokemonType.fire;
  PokemonType _weakness     = PokemonType.water;
  PokemonPosition _position = PokemonPosition.bench;
  String? _imagePath;
  bool _weaknessEdited      = false;
  PokemonStage _stage       = PokemonStage.basic;

  // Deck linking
  String? _selectedDeckId;
  DeckCard? _selectedDeckCard;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _nameController.text = p.name;
      _hpController.text   = p.baseMaxHp.toString();
      _type                = p.type;
      _weakness            = p.weakness;
      _position            = p.position;
      _imagePath           = p.imagePath;
      _weaknessEdited      = true;
      _stage               = p.stage;
    }
  }

  @override
  void dispose() { _nameController.dispose(); _hpController.dispose(); super.dispose(); }

  void _onTypeChanged(PokemonType t) => setState(() {
    _type = t;
    if (!_weaknessEdited) _weakness = t.defaultWeakness;
  });

  void _applyDeckCard(DeckCard card) {
    setState(() {
      _selectedDeckCard = card;
      _nameController.text = card.name;
      if (card.pokemonHp != null) _hpController.text = card.pokemonHp.toString();
      if (card.pokemonType != null) { _type = card.pokemonType!; }
      if (card.pokemonWeakness != null) { _weakness = card.pokemonWeakness!; _weaknessEdited = true; }
      if (card.imagePath != null) _imagePath = card.imagePath;
      _stage = card.stage;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submit() {
    final name = _nameController.text.trim();
    final hp   = int.tryParse(_hpController.text);
    if (name.isEmpty || hp == null || hp <= 0) return;
    final provider = context.read<BattleProvider>();
    if (widget.existing != null) {
      provider.updatePokemon(widget.existing!.id, widget.existing!.copyWith(
        name: name, baseMaxHp: hp, type: _type, weakness: _weakness,
        position: _position, imagePath: _imagePath, stage: _stage,
        deckCardId: _selectedDeckCard?.id ?? widget.existing!.deckCardId,
      ));
    } else {
      provider.addPokemon(Pokemon(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name, baseMaxHp: hp, type: _type, weakness: _weakness,
        position: _position, imagePath: _imagePath, stage: _stage,
        deckCardId: _selectedDeckCard?.id,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final deckProvider = context.watch<DeckProvider>();
    final decks = deckProvider.decks;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(isEdit ? 'EDITAR POKÉMON' : 'ADICIONAR POKÉMON',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            // ── Vincular com deck ──
            if (!isEdit && decks.isNotEmpty) ...[
              _SectionLabel(label: 'SELECIONAR DO DECK'),
              const SizedBox(height: 8),
              // Seletor de deck
              DropdownButtonFormField<String>(
                value: _selectedDeckId,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(labelText: 'Deck'),
                style: const TextStyle(color: AppTheme.textPrimary),
                items: decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                onChanged: (id) => setState(() { _selectedDeckId = id; _selectedDeckCard = null; }),
              ),
              // Seletor de carta do deck
              if (_selectedDeckId != null) ...[
                const SizedBox(height: 8),
                Builder(builder: (_) {
                  final deck = deckProvider.getDeck(_selectedDeckId!);
                  final pkmnCards = deck?.pokemonCards ?? [];
                  if (pkmnCards.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhum Pokémon cadastrado neste deck.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pkmnCards.map((card) {
                      final isSelected = _selectedDeckCard?.id == card.id;
                      final typeColor = card.pokemonType != null ? Color(card.pokemonType!.colorValue) : AppTheme.accent;
                      return GestureDetector(
                        onTap: () => _applyDeckCard(card),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? typeColor.withOpacity(0.12) : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? typeColor : AppTheme.divider, width: isSelected ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            if (card.imagePath != null)
                              Container(
                                width: 28, height: 38, margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(File(card.imagePath!), fit: BoxFit.cover),
                              ),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(card.name, style: TextStyle(color: isSelected ? typeColor : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                              if (card.pokemonType != null)
                                Text('${card.pokemonType!.label} · ${card.pokemonHp ?? "??"} HP',
                                  style: TextStyle(color: typeColor.withOpacity(0.7), fontSize: 11)),
                            ])),
                            Text('x${card.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle, color: typeColor, size: 18),
                            ],
                          ]),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
              Container(height: 1, color: AppTheme.divider, margin: const EdgeInsets.symmetric(vertical: 12)),
            ],

            // ── Foto da carta ──
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120, height: 168,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _imagePath != null ? Color(_type.colorValue).withOpacity(0.6) : AppTheme.divider, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary, size: 32),
                          const SizedBox(height: 6),
                          const Text('Foto da carta', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                        ]),
                ),
              ),
            ),
            if (_imagePath != null)
              Center(child: TextButton.icon(
                onPressed: () => setState(() => _imagePath = null),
                icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.textSecondary),
                label: const Text('Remover foto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              )),
            const SizedBox(height: 14),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome do Pokémon'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 10),
            TextField(controller: _hpController, decoration: const InputDecoration(labelText: 'HP Máximo'), keyboardType: TextInputType.number),
            const SizedBox(height: 14),

            // Estágio
            _SectionLabel(label: 'ESTÁGIO DE EVOLUÇÃO'),
            const SizedBox(height: 8),
            Row(
              children: PokemonStage.values.map((stage) {
                final isSelected = _stage == stage;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _stage = stage),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent.withOpacity(0.12) : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.divider, width: isSelected ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(
                          stage.label.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Posição
            _SectionLabel(label: 'POSIÇÃO NO CAMPO'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _PosButton(label: 'ATIVO', icon: Icons.flash_on, selected: _position == PokemonPosition.active,
                  onTap: () => setState(() => _position = PokemonPosition.active))),
              const SizedBox(width: 10),
              Expanded(child: _PosButton(label: 'BANCO', icon: Icons.chair_outlined, selected: _position == PokemonPosition.bench,
                  color: AppTheme.textSecondary, onTap: () => setState(() => _position = PokemonPosition.bench))),
            ]),
            const SizedBox(height: 14),

            // Tipo
            _SectionLabel(label: 'TIPO'),
            const SizedBox(height: 8),
            _TypeGrid(selected: _type, onSelect: _onTypeChanged),
            const SizedBox(height: 14),

            // Fraqueza
            Row(children: [
              const _SectionLabel(label: 'FRAQUEZA'),
              const SizedBox(width: 6),
              Text('(automática · toque para editar)', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            _TypeGrid(selected: _weakness, onSelect: (t) => setState(() { _weakness = t; _weaknessEdited = true; }), highlightColor: AppTheme.hpRed),
            const SizedBox(height: 16),

            SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'SALVAR' : 'ADICIONAR'))),
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
  Widget build(BuildContext context) => Text(label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, letterSpacing: 1.2));
}

class _PosButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _PosButton({required this.label, required this.icon, required this.selected, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c : AppTheme.divider, width: selected ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? c : AppTheme.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? c : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  final PokemonType selected;
  final void Function(PokemonType) onSelect;
  final Color? highlightColor;
  const _TypeGrid({required this.selected, required this.onSelect, this.highlightColor});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6, runSpacing: 6,
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
          child: Text(type.label, style: TextStyle(
            color: isSelected ? (highlightColor ?? color) : color.withOpacity(0.7),
            fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
        ),
      );
    }).toList(),
  );
}
