// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../models/tool_card.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';
import 'hp_bar.dart';
import 'damage_dialog.dart';
import 'add_pokemon_sheet.dart';
import 'tool_card_sheet.dart';
import 'evolve_pokemon_sheet.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BattleProvider>();
    final typeColor = Color(pokemon.type.colorValue);
    final weakColor = Color(pokemon.weakness.colorValue);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: pokemon.isFainted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pokemon.isFainted
                ? AppTheme.hpRed.withOpacity(0.5)
                : pokemon.isActive
                    ? typeColor.withOpacity(0.7)
                    : typeColor.withOpacity(0.25),
            width: pokemon.isActive ? 2 : 1.5,
          ),
          boxShadow: [
            if (pokemon.isActive)
              BoxShadow(color: typeColor.withOpacity(0.2), blurRadius: 16, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(pokemon.isActive ? 0.18 : 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  if (pokemon.imageFile != null)
                    GestureDetector(
                      onTap: () => _showCardImage(context),
                      child: Container(
                        width: 36, height: 50,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: typeColor.withOpacity(0.5)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(pokemon.imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Posição badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: pokemon.isActive
                                  ? AppTheme.accent.withOpacity(0.2)
                                  : AppTheme.divider,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: pokemon.isActive ? AppTheme.accent : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              pokemon.isActive ? '⚔ ATIVO' : '🪑 BANCO',
                              style: TextStyle(
                                color: pokemon.isActive ? AppTheme.accent : AppTheme.textSecondary,
                                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              pokemon.type.label.toUpperCase(),
                              style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Text(
                              pokemon.stage.label.toUpperCase(),
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(pokemon.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  const Spacer(),
                  if (pokemon.isFainted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.hpRed.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
                      child: const Text('NOCAUTEADO', style: TextStyle(color: AppTheme.hpRed, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _showOptions(context, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Fraqueza + bônus de ferramentas
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  const Text('Fraqueza: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: weakColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(pokemon.weakness.label, style: TextStyle(color: weakColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (pokemon.hasImmunity)
                    const _StatBadge(label: '🛡 IMUNE', color: Color(0xFF7E57C2)),
                  if (pokemon.hasImmunity && (pokemon.damageBonus > 0 || pokemon.maxHp != pokemon.baseMaxHp))
                    const SizedBox(width: 4),
                  if (pokemon.damageBonus > 0)
                    _StatBadge(label: '+${pokemon.damageBonus} DMG', color: AppTheme.hpRed),
                  if (pokemon.damageBonus > 0 && pokemon.maxHp != pokemon.baseMaxHp)
                    const SizedBox(width: 4),
                  if (pokemon.maxHp != pokemon.baseMaxHp)
                    _StatBadge(label: '+${pokemon.maxHp - pokemon.baseMaxHp} HP', color: AppTheme.hpGreen),
                ],
              ),
            ),

            // Ferramentas anexadas (chips)
            if (pokemon.tools.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pokemon.tools.map((t) => _ToolChip(tool: t)).toList(),
                  ),
                ),
              ),

            // HP Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: HpBar(currentHp: pokemon.currentHp, maxHp: pokemon.maxHp),
            ),

            // Big HP number
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${pokemon.currentHp}',
                    style: TextStyle(
                      color: AppTheme.hpColor(pokemon.hpPercent),
                      fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${pokemon.maxHp} HP',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'CURAR',
                      icon: Icons.favorite,
                      color: AppTheme.hpGreen,
                      onTap: () => _openDialog(context, provider, isHeal: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionButton(
                      label: 'DANO',
                      icon: Icons.flash_on,
                      color: AppTheme.hpRed,
                      onTap: () => _openDialog(context, provider, isHeal: false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    label: '',
                    icon: Icons.construction,
                    color: AppTheme.textSecondary,
                    onTap: () => _openToolSheet(context, provider),
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, BattleProvider provider, {required bool isHeal}) {
    showDialog(
      context: context,
      builder: (_) => DamageDialog(pokemon: pokemon, provider: provider, isHeal: isHeal),
    );
  }

  void _openToolSheet(BuildContext context, BattleProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ToolCardSheet(pokemon: pokemon, provider: provider),
    );
  }

  void _showCardImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(pokemon.imageFile!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, BattleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          // Toggle posição
          ListTile(
            leading: Icon(
              pokemon.isActive ? Icons.chair_outlined : Icons.flash_on,
              color: AppTheme.accent,
            ),
            title: Text(
              pokemon.isActive ? 'Mover para o banco' : 'Colocar como ativo',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            onTap: () {
              provider.setPosition(
                pokemon.id,
                pokemon.isActive ? PokemonPosition.bench : PokemonPosition.active,
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.upgrade_rounded,
              color: pokemon.stage == PokemonStage.stage2 ? AppTheme.textSecondary.withOpacity(0.4) : AppTheme.accent,
            ),
            title: Text(
              pokemon.stage == PokemonStage.stage2 ? 'Evoluir Pokémon (Estágio Máximo)' : 'Evoluir Pokémon',
              style: TextStyle(color: pokemon.stage == PokemonStage.stage2 ? AppTheme.textSecondary.withOpacity(0.6) : AppTheme.textPrimary),
            ),
            enabled: pokemon.stage != PokemonStage.stage2,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => EvolvePokemonSheet(pokemon: pokemon, provider: provider),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
            title: const Text('Editar Pokémon', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => AddPokemonSheet(existing: pokemon),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.healing, color: AppTheme.hpGreen),
            title: const Text('Curar completamente', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () { provider.fullHeal(pokemon.id); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.hpRed),
            title: const Text('Remover da batalha', style: TextStyle(color: AppTheme.hpRed)),
            onTap: () { provider.removePokemon(pokemon.id); Navigator.pop(context); },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _ToolChip extends StatelessWidget {
  final ToolCard tool;
  const _ToolChip({required this.tool});
  @override
  Widget build(BuildContext context) {
    final color = tool.effect == ToolEffect.hpBonus ? AppTheme.hpGreen
                : tool.effect == ToolEffect.damageBonus ? AppTheme.hpRed
                : AppTheme.textSecondary;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 10, color: color),
          const SizedBox(width: 4),
          Text(tool.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: compact ? 14 : 0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: compact
            ? Icon(icon, color: color, size: 18)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)),
                ],
              ),
      ),
    );
  }
}
