// lib/widgets/tool_card_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/deck_card.dart';
import '../models/pokemon.dart';
import '../models/tool_card.dart';
import '../providers/battle_provider.dart';
import '../providers/deck_provider.dart';
import '../theme/app_theme.dart';

class ToolCardSheet extends StatefulWidget {
  final Pokemon pokemon;
  final BattleProvider provider;
  const ToolCardSheet({super.key, required this.pokemon, required this.provider});
  @override
  State<ToolCardSheet> createState() => _ToolCardSheetState();
}

class _ToolCardSheetState extends State<ToolCardSheet> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _valueCtrl = TextEditingController();
  ToolEffect _effect = ToolEffect.none;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _addManual() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final value = int.tryParse(_valueCtrl.text) ?? 0;
    widget.provider.addTool(widget.pokemon.id, ToolCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: _descCtrl.text.trim(),
      effect: _effect,
      value: _effect == ToolEffect.none ? 0 : value,
    ));
    _nameCtrl.clear();
    _descCtrl.clear();
    _valueCtrl.clear();
    setState(() => _effect = ToolEffect.none);
  }

  void _addFromDeck(DeckCard card) {
    widget.provider.addTool(widget.pokemon.id, ToolCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: card.name,
      description: card.description,
      effect: card.toolEffect,
      value: card.toolEffectValue,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tools = widget.pokemon.tools;
    final deckProvider = context.watch<DeckProvider>();
    final allToolCards = deckProvider.decks.expand((d) => d.toolCards).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.construction, color: AppTheme.accent, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'FERRAMENTAS — ${widget.pokemon.name}',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Ferramentas já anexadas
          if (tools.isNotEmpty) ...[
            const Text('ANEXADAS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            ...tools.map((t) => _ToolItem(tool: t, onRemove: () => widget.provider.removeTool(widget.pokemon.id, t.id))),
            const SizedBox(height: 10),
            Container(height: 1, color: AppTheme.divider),
            const SizedBox(height: 10),
          ],

          TabBar(
            controller: _tab,
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1),
            tabs: [
              Tab(text: 'DO DECK (${allToolCards.where((c) => c.isAttachable).length})'),
              const Tab(text: 'MANUAL'),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tab,
              children: [
                // ── Aba: do deck ──
                Builder(builder: (_) {
                  final attachable = allToolCards.where((c) => c.isAttachable).toList();
                  if (attachable.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nenhuma ferramenta com efeito cadastrada no deck.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    children: attachable.map((card) {
                      final eColor = Color(card.toolEffect.colorValue);
                      return GestureDetector(
                        onTap: () => _addFromDeck(card),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: eColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: eColor.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.construction, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(card.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                              if (card.description.isNotEmpty)
                                Text(card.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ])),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: eColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                (card.toolEffect == ToolEffect.hpBonus || card.toolEffect == ToolEffect.damageBonus)
                                    ? '+${card.toolEffectValue} ${card.toolEffect == ToolEffect.hpBonus ? "HP" : "DMG"}'
                                    : card.toolEffect.label,
                                style: TextStyle(color: eColor, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.add_circle_outline, color: eColor, size: 20),
                          ]),
                        ),
                      );
                    }).toList(),
                  );
                }),

                // ── Aba: manual ──
                SingleChildScrollView(
                  child: Column(children: [
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome da carta')),
                    const SizedBox(height: 8),
                    TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descricao (opcional)')),
                    const SizedBox(height: 10),
                    Row(children: [
                      _EffectChip(label: 'Sem efeito', effect: ToolEffect.none,        selected: _effect, onTap: (e) => setState(() => _effect = e)),
                      const SizedBox(width: 6),
                      _EffectChip(label: '+HP',       effect: ToolEffect.hpBonus,      selected: _effect, onTap: (e) => setState(() => _effect = e)),
                      const SizedBox(width: 6),
                      _EffectChip(label: '+DMG',      effect: ToolEffect.damageBonus,  selected: _effect, onTap: (e) => setState(() => _effect = e)),
                      const SizedBox(width: 6),
                      _EffectChip(label: 'Imune',     effect: ToolEffect.immunity,     selected: _effect, onTap: (e) => setState(() => _effect = e)),
                    ]),
                    if (_effect == ToolEffect.hpBonus || _effect == ToolEffect.damageBonus) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: _effect == ToolEffect.hpBonus ? 'Bonus de HP' : 'Bonus de dano',
                          prefixText: '+',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addManual,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ANEXAR'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final ToolCard tool;
  final VoidCallback onRemove;
  const _ToolItem({required this.tool, required this.onRemove});

  Color get _color {
    switch (tool.effect) {
      case ToolEffect.hpBonus:     return AppTheme.hpGreen;
      case ToolEffect.damageBonus: return AppTheme.hpRed;
      case ToolEffect.immunity:    return const Color(0xFF7E57C2);
      case ToolEffect.none:        return AppTheme.textSecondary;
    }
  }

  String get _label {
    switch (tool.effect) {
      case ToolEffect.hpBonus:     return '+${tool.value} HP';
      case ToolEffect.damageBonus: return '+${tool.value} DMG';
      case ToolEffect.immunity:    return 'Imunidade';
      case ToolEffect.none:        return 'Visual';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.construction, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tool.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        if (tool.description.isNotEmpty)
          Text(tool.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 8),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary)),
    ]),
  );
}

class _EffectChip extends StatelessWidget {
  final String label;
  final ToolEffect effect;
  final ToolEffect selected;
  final void Function(ToolEffect) onTap;
  const _EffectChip({required this.label, required this.effect, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = effect == selected;
    final color = effect == ToolEffect.hpBonus     ? AppTheme.hpGreen
                : effect == ToolEffect.damageBonus  ? AppTheme.hpRed
                : effect == ToolEffect.immunity     ? const Color(0xFF7E57C2)
                : AppTheme.textSecondary;
    return GestureDetector(
      onTap: () => onTap(effect),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : AppTheme.divider, width: active ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(
          color: active ? color : AppTheme.textSecondary,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontSize: 11,
        )),
      ),
    );
  }
}
