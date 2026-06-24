// lib/widgets/damage_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pokemon.dart';
import '../providers/battle_provider.dart';
import '../theme/app_theme.dart';

enum _DamageMode { damage, heal }

class DamageDialog extends StatefulWidget {
  final Pokemon pokemon;
  final BattleProvider provider;
  final bool isHeal;

  const DamageDialog({
    super.key,
    required this.pokemon,
    required this.provider,
    this.isHeal = false,
  });

  @override
  State<DamageDialog> createState() => _DamageDialogState();
}

class _DamageDialogState extends State<DamageDialog> {
  late _DamageMode _mode;
  final _controller = TextEditingController();
  bool _applyWeakness = false;
  int? _customValue;

  final _presets = [10, 20, 30, 40, 50, 60, 80, 100, 120, 180, 200, 250];

  @override
  void initState() {
    super.initState();
    _mode = widget.isHeal ? _DamageMode.heal : _DamageMode.damage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _effectiveValue {
    final base = _customValue ?? 0;
    if (_mode == _DamageMode.damage && _applyWeakness) return base * 2;
    return base;
  }

  void _confirm() {
    final val = _customValue;
    if (val == null || val <= 0) return;
    if (_mode == _DamageMode.heal) {
      widget.provider.healPokemon(widget.pokemon.id, val);
    } else {
      widget.provider.applyDamage(widget.pokemon.id, _effectiveValue);
    }
    Navigator.pop(context);
  }

  void _selectPreset(int value) {
    setState(() {
      _customValue = value;
      _controller.text = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDamage = _mode == _DamageMode.damage;
    final accentColor = isDamage ? AppTheme.hpRed : AppTheme.hpGreen;
    final weaknessType = widget.pokemon.weakness;
    final typeColor = Color(accentColor.value);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle dano/cura
            Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'DANO',
                    icon: Icons.flash_on,
                    active: isDamage,
                    color: AppTheme.hpRed,
                    onTap: () => setState(() { _mode = _DamageMode.damage; _applyWeakness = false; }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeTab(
                    label: 'CURA',
                    icon: Icons.favorite,
                    active: !isDamage,
                    color: AppTheme.hpGreen,
                    onTap: () => setState(() { _mode = _DamageMode.heal; _applyWeakness = false; }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aviso de imunidade
            if (widget.pokemon.hasImmunity && _mode == _DamageMode.damage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7E57C2).withOpacity(0.5)),
                ),
                child: const Row(children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF7E57C2), size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Este Pokémon tem imunidade a efeitos externos.',
                    style: TextStyle(color: Color(0xFF7E57C2), fontSize: 12, fontWeight: FontWeight.w600),
                  )),
                ]),
              ),

            // Nome do Pokémon
            Text(
              widget.pokemon.name,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),

            // Valor digitado + preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: typeColor.withOpacity(0.3), fontSize: 36, fontWeight: FontWeight.w800),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixText: isDamage ? '-' : '+',
                      prefixStyle: TextStyle(color: typeColor, fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    onChanged: (v) => setState(() => _customValue = int.tryParse(v)),
                  ),
                ),
                if (_applyWeakness && _customValue != null && _customValue! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'x2 fraqueza',
                          style: TextStyle(color: AppTheme.hpRed.withOpacity(0.7), fontSize: 11),
                        ),
                        Text(
                          '= ${_effectiveValue}',
                          style: const TextStyle(
                            color: AppTheme.hpRed,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Linha divisória
            Container(height: 1, color: AppTheme.divider),
            const SizedBox(height: 12),

            // Presets rápidos
            Text(
              'RÁPIDO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presets.map((v) {
                final isSelected = _customValue == v;
                return GestureDetector(
                  onTap: () => _selectPreset(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? typeColor.withOpacity(0.2) : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? typeColor : AppTheme.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '$v',
                      style: TextStyle(
                        color: isSelected ? typeColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Fraqueza toggle (só no modo dano)
            if (isDamage) ...[
              GestureDetector(
                onTap: () => setState(() => _applyWeakness = !_applyWeakness),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _applyWeakness
                        ? AppTheme.hpRed.withOpacity(0.12)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _applyWeakness
                          ? AppTheme.hpRed.withOpacity(0.6)
                          : AppTheme.divider,
                      width: _applyWeakness ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _applyWeakness ? AppTheme.hpRed : AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aplicar fraqueza (x2)',
                              style: TextStyle(
                                color: _applyWeakness ? AppTheme.hpRed : AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Fraqueza: ${weaknessType.label}',
                              style: TextStyle(
                                color: Color(weaknessType.colorValue),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _applyWeakness ? Icons.check_box : Icons.check_box_outline_blank,
                        color: _applyWeakness ? AppTheme.hpRed : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botão confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_customValue != null && _customValue! > 0) ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  disabledBackgroundColor: AppTheme.divider,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isDamage
                      ? (_applyWeakness ? 'APLICAR ${_effectiveValue} DMG (x2)' : 'APLICAR DANO')
                      : 'APLICAR CURA',
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : AppTheme.divider,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : AppTheme.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppTheme.textSecondary,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
