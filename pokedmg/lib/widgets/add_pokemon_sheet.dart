// lib/widgets/add_pokemon_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';

class AddPokemonSheet extends StatefulWidget {
  const AddPokemonSheet({super.key});

  @override
  State<AddPokemonSheet> createState() => _AddPokemonSheetState();
}

class _AddPokemonSheetState extends State<AddPokemonSheet> {
  final _nameController = TextEditingController();
  final _hpController = TextEditingController(text: '120');
  PokemonType _selectedType = PokemonType.normal;

  @override
  void dispose() {
    _nameController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final hp = int.tryParse(_hpController.text);
    if (name.isEmpty || hp == null || hp <= 0) return;

    context.read<BattleProvider>().addPokemon(
      Pokemon(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        maxHp: hp,
        type: _selectedType,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ADICIONAR POKÉMON',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome do Pokémon'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hpController,
            decoration: const InputDecoration(labelText: 'HP Máximo'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Text(
            'TIPO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PokemonType.values.map((type) {
              final color = Color(type.colorValue);
              final isSelected = type == _selectedType;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected ? color : color.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('ADICIONAR'),
            ),
          ),
        ],
      ),
    );
  }
}
