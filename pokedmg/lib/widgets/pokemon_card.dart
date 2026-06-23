// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';
import 'hp_bar.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BattleProvider>();
    final step = context.select<BattleProvider, int>((p) => p.damageStep);
    final typeColor = Color(pokemon.type.colorValue);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: pokemon.isFainted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pokemon.isFainted
                ? AppTheme.hpRed.withOpacity(0.5)
                : typeColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: typeColor.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: typeColor.withOpacity(0.6)),
                    ),
                    child: Text(
                      pokemon.type.label.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pokemon.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pokemon.isFainted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.hpRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NOCAUTEADO',
                        style: TextStyle(
                          color: AppTheme.hpRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                    onPressed: () => _showOptions(context, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // HP Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: HpBar(currentHp: pokemon.currentHp, maxHp: pokemon.maxHp),
            ),

            // Big HP number
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${pokemon.currentHp}',
                      style: TextStyle(
                        color: AppTheme.hpColor(pokemon.hpPercent),
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${pokemon.maxHp} HP',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  // Heal button
                  Expanded(
                    child: _ControlButton(
                      label: '+$step',
                      sublabel: 'CURAR',
                      color: AppTheme.hpGreen,
                      icon: Icons.favorite,
                      onTap: () => provider.healPokemon(pokemon.id, step),
                      onLongPress: () => _showCustomAmount(context, provider, heal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Damage button
                  Expanded(
                    child: _ControlButton(
                      label: '-$step',
                      sublabel: 'DANO',
                      color: AppTheme.hpRed,
                      icon: Icons.flash_on,
                      onTap: () => provider.applyDamage(pokemon.id, step),
                      onLongPress: () => _showCustomAmount(context, provider, heal: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, BattleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.healing, color: AppTheme.hpGreen),
            title: const Text('Curar completamente', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              provider.fullHeal(pokemon.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.hpRed),
            title: const Text('Remover da batalha', style: TextStyle(color: AppTheme.hpRed)),
            onTap: () {
              provider.removePokemon(pokemon.id);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCustomAmount(BuildContext context, BattleProvider provider, {required bool heal}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          heal ? 'Cura personalizada' : 'Dano personalizado',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: heal ? 'Quantidade de HP' : 'Dano',
            prefixText: heal ? '+' : '-',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                heal
                    ? provider.healPokemon(pokemon.id, val)
                    : provider.applyDamage(pokemon.id, val);
              }
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ControlButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
