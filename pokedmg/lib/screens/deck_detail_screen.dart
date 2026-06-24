// lib/screens/deck_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/deck_card.dart';
import '../models/tool_card.dart';
import '../models/pokemon.dart';
import '../providers/deck_provider.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class DeckDetailScreen extends StatefulWidget {
  final String deckId;
  const DeckDetailScreen({super.key, required this.deckId});
  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeckProvider>();
    final deck = provider.getDeck(widget.deckId);
    if (deck == null) return const Scaffold(body: Center(child: Text('Deck não encontrado')));

    final total = deck.totalCards;
    final full  = deck.isFull;
    final toolTrainerCards = [...deck.toolCards, ...deck.trainerCards];

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: full ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: full ? AppTheme.accent : AppTheme.divider),
            ),
            child: Text('$total / ${Deck.maxCards}',
              style: TextStyle(color: full ? AppTheme.accent : AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          PopupMenuButton(
            color: AppTheme.surface,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(child: const Text('Editar deck', style: TextStyle(color: AppTheme.textPrimary)), onTap: () => _editDeck(context, deck)),
              PopupMenuItem(child: const Text('Excluir deck', style: TextStyle(color: AppTheme.hpRed)),    onTap: () => _deleteDeck(context)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8),
          tabs: [
            Tab(text: 'BARALHO  ${deck.totalCards}'),
            Tab(text: 'POKÉMON  ${deck.pokemonCards.fold(0,(s,c)=>s+c.quantity)}'),
            Tab(text: 'TREINADORES  ${toolTrainerCards.fold(0,(s,c)=>s+c.quantity)}'),
            Tab(text: 'ENERGIA  ${deck.energyCards.fold(0,(s,c)=>s+c.quantity)}'),
            const Tab(text: 'GERENCIAR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── BARALHO: todas as cartas em grid ──
          _CardGrid(deckId: deck.id, cards: deck.cards),
          // ── POKÉMON ──
          _CardGrid(deckId: deck.id, cards: deck.pokemonCards),
          // ── TREINADORES (ferramenta + treinador) ──
          _CardGrid(deckId: deck.id, cards: toolTrainerCards),
          // ── ENERGIA ──
          _CardGrid(deckId: deck.id, cards: deck.energyCards),
          // ── GERENCIAR: lista com controles de quantidade ──
          _ManageList(deckId: deck.id, deck: deck),
        ],
      ),
      floatingActionButton: _tab.index == 4 && !full
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMixedCard(context, deck.id),
              icon: const Icon(Icons.add),
              label: const Text('CARTA', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            )
          : null,
    );
  }

  void _editDeck(BuildContext context, Deck deck) {
    final nameCtrl = TextEditingController(text: deck.name);
    final descCtrl = TextEditingController(text: deck.description);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Editar deck', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 10),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(onPressed: () {
          context.read<DeckProvider>().updateDeckMeta(deck.id, name: nameCtrl.text.trim(), description: descCtrl.text.trim());
          Navigator.pop(context);
        }, child: const Text('SALVAR')),
      ],
    ));
  }

  void _deleteDeck(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Excluir deck?', style: TextStyle(color: AppTheme.textPrimary)),
      content: const Text('Essa ação não pode ser desfeita.', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hpRed),
          onPressed: () { context.read<DeckProvider>().deleteDeck(widget.deckId); Navigator.pop(context); Navigator.pop(context); },
          child: const Text('EXCLUIR'),
        ),
      ],
    ));
  }

  void _showAddMixedCard(BuildContext context, String deckId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('ADICIONAR CARTA', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        ListTile(leading: const Icon(Icons.catching_pokemon, color: Color(0xFFE63946)),  title: const Text('Pokémon',     style: TextStyle(color: AppTheme.textPrimary)), onTap: () { Navigator.pop(context); _showAddCard(context, deckId, DeckCardType.pokemon); }),
        ListTile(leading: const Icon(Icons.construction,     color: Color(0xFF78909C)),  title: const Text('Ferramenta',  style: TextStyle(color: AppTheme.textPrimary)), onTap: () { Navigator.pop(context); _showAddCard(context, deckId, DeckCardType.tool); }),
        ListTile(leading: const Icon(Icons.person_outline,   color: Color(0xFF42A5F5)),  title: const Text('Treinador',   style: TextStyle(color: AppTheme.textPrimary)), onTap: () { Navigator.pop(context); _showAddCard(context, deckId, DeckCardType.trainer); }),
        ListTile(leading: const Icon(Icons.bolt,             color: Color(0xFFFFCA28)),  title: const Text('Energia',     style: TextStyle(color: AppTheme.textPrimary)), onTap: () { Navigator.pop(context); _showAddCard(context, deckId, DeckCardType.energy); }),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _showAddCard(BuildContext context, String deckId, DeckCardType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCardSheet(deckId: deckId, type: type),
    );
  }
}

// ─── Grid de cartas estilo TCG Live ──────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  final String deckId;
  final List<DeckCard> cards;
  const _CardGrid({required this.deckId, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('Nenhuma carta', style: TextStyle(color: AppTheme.textSecondary)),
        ]).animate().fadeIn(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.68,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _CardGridItem(deckId: deckId, card: cards[i])
          .animate()
          .fadeIn(duration: 150.ms, delay: Duration(milliseconds: i * 20))
          .scale(begin: const Offset(0.9, 0.9), duration: 150.ms),
    );
  }
}

class _CardGridItem extends StatelessWidget {
  final String deckId;
  final DeckCard card;
  const _CardGridItem({required this.deckId, required this.card});

  @override
  Widget build(BuildContext context) {
    final typeColor = Color(card.type.colorValue);

    return GestureDetector(
      onTap: () => _showCardDetail(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card body
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor.withOpacity(0.35), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: card.imagePath != null
                ? Image.file(File(card.imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : _CardPlaceholder(card: card),
          ),

          // Quantidade badge (canto inferior direito, estilo TCG Live)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Center(
                child: Text(
                  '${card.quantity}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCardDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Foto em destaque
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: card.imagePath != null
                  ? Image.file(File(card.imagePath!), fit: BoxFit.contain)
                  : _CardDetailPlaceholder(card: card),
            ),
            const SizedBox(height: 12),
            // Infos abaixo da foto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(card.type.colorValue).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(card.type.label.toUpperCase(),
                        style: TextStyle(color: Color(card.type.colorValue), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                    if (card.pokemonType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(card.pokemonType!.colorValue).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(card.pokemonType!.label.toUpperCase(),
                          style: TextStyle(color: Color(card.pokemonType!.colorValue), fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(8)),
                      child: Text('x${card.quantity}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(card.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  if (card.pokemonHp != null) ...[
                    const SizedBox(height: 2),
                    Text('${card.stage.label} · ${card.pokemonHp} HP', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    if (card.preEvolutionId != null) ...[
                      Builder(builder: (context) {
                        final deck = context.read<DeckProvider>().getDeck(deckId);
                        final preEv = deck?.cards.where((c) => c.id == card.preEvolutionId).firstOrNull;
                        if (preEv != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Evolui de: ${preEv.name}',
                              style: const TextStyle(color: AppTheme.hpYellow, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ],
                  if (card.pokemonWeakness != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Text('Fraqueza: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(card.pokemonWeakness!.label,
                        style: TextStyle(color: Color(card.pokemonWeakness!.colorValue), fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                  if (card.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(card.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR', style: TextStyle(color: AppTheme.textSecondary, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  final DeckCard card;
  const _CardPlaceholder({required this.card});
  @override
  Widget build(BuildContext context) {
    final color = Color(card.type.colorValue);
    return Container(
      color: color.withOpacity(0.08),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_typeIcon(card.type), color: color.withOpacity(0.5), size: 22),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(card.name, style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _CardDetailPlaceholder extends StatelessWidget {
  final DeckCard card;
  const _CardDetailPlaceholder({required this.card});
  @override
  Widget build(BuildContext context) {
    final color = Color(card.type.colorValue);
    return Container(
      height: 240,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_typeIcon(card.type), color: color, size: 48),
        const SizedBox(height: 12),
        Text(card.name, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      ])),
    );
  }
}

IconData _typeIcon(DeckCardType type) {
  switch (type) {
    case DeckCardType.pokemon:  return Icons.catching_pokemon;
    case DeckCardType.tool:     return Icons.construction;
    case DeckCardType.energy:   return Icons.bolt;
    case DeckCardType.trainer:  return Icons.person_outline;
  }
}

// ─── Aba Gerenciar: lista com controles ──────────────────────────────────────

class _ManageList extends StatelessWidget {
  final String deckId;
  final Deck deck;
  const _ManageList({required this.deckId, required this.deck});

  @override
  Widget build(BuildContext context) {
    final allCards = deck.cards;
    if (allCards.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('Nenhuma carta ainda', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('Use o botão + para adicionar', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]).animate().fadeIn(),
      );
    }

    // Agrupar por tipo
    final groups = <DeckCardType, List<DeckCard>>{};
    for (final t in DeckCardType.values) {
      final list = allCards.where((c) => c.type == t).toList();
      if (list.isNotEmpty) groups[t] = list;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: groups.entries.expand((entry) {
        final color = Color(entry.key.colorValue);
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(entry.key.label.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(width: 6),
              Text('(${entry.value.fold(0,(s,c)=>s+c.quantity)})', style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
            ]),
          ),
          ...entry.value.map((card) => _ManageCardTile(deckId: deckId, card: card, deck: deck)
              .animate().fadeIn(duration: 150.ms)),
          const SizedBox(height: 8),
        ];
      }).toList(),
    );
  }
}

class _ManageCardTile extends StatelessWidget {
  final String deckId;
  final DeckCard card;
  final Deck deck;
  const _ManageCardTile({required this.deckId, required this.card, required this.deck});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeckProvider>();
    final typeColor = Color(card.type.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.25)),
      ),
      child: Row(children: [
        if (card.imagePath != null)
          Container(
            width: 32, height: 44, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.antiAlias,
            child: Image.file(File(card.imagePath!), fit: BoxFit.cover),
          ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(card.type.label.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            if (card.pokemonType != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Color(card.pokemonType!.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(card.pokemonType!.label.toUpperCase(), style: TextStyle(color: Color(card.pokemonType!.colorValue), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
            if (card.pokemonHp != null) ...[
              const SizedBox(width: 4),
              Text('${card.stage.label} · ${card.pokemonHp} HP', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ]),
          const SizedBox(height: 3),
          Text(card.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          if (card.description.isNotEmpty)
            Text(card.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        // Controles de quantidade
        Row(children: [
          _QtyBtn(icon: Icons.remove, onTap: () => provider.setQuantity(deckId, card.id, card.quantity - 1)),
          Container(width: 34, alignment: Alignment.center,
            child: Text('${card.quantity}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16))),
          _QtyBtn(icon: Icons.add, enabled: card.canAddMore && !deck.isFull,
            onTap: () => provider.setQuantity(deckId, card.id, card.quantity + 1)),
        ]),
        PopupMenuButton(
          color: AppTheme.surface,
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Editar carta', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Future.microtask(() => showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: AppTheme.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _AddCardSheet(deckId: deckId, type: card.type, existing: card),
              )),
            ),
            PopupMenuItem(
              child: const Text('Remover carta', style: TextStyle(color: AppTheme.hpRed)),
              onTap: () => provider.removeCard(deckId, card.id),
            ),
          ],
        ),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _QtyBtn({required this.icon, required this.onTap, this.enabled = true});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: enabled ? AppTheme.textPrimary : AppTheme.divider),
    ),
  );
}

// ─── Sheet adicionar/editar carta ────────────────────────────────────────────

class _AddCardSheet extends StatefulWidget {
  final String deckId;
  final DeckCardType type;
  final DeckCard? existing;
  const _AddCardSheet({required this.deckId, required this.type, this.existing});
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _nameCtrl      = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _hpCtrl        = TextEditingController();
  final _toolValueCtrl = TextEditingController();
  PokemonType _pkmnType     = PokemonType.fire;
  PokemonType _pkmnWeakness = PokemonType.water;
  ToolEffect  _toolEffect   = ToolEffect.none;
  String? _imagePath;
  PokemonStage _pkmnStage   = PokemonStage.basic;
  String? _preEvolutionId;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final c = widget.existing!;
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      if (c.pokemonHp != null) _hpCtrl.text = c.pokemonHp.toString();
      if (c.pokemonType != null) _pkmnType = c.pokemonType!;
      if (c.pokemonWeakness != null) _pkmnWeakness = c.pokemonWeakness!;
      if (c.pokemonStage != null) _pkmnStage = c.pokemonStage!;
      if (c.preEvolutionId != null) _preEvolutionId = c.preEvolutionId;
      _toolEffect = c.toolEffect;
      if (c.toolEffectValue > 0) _toolValueCtrl.text = c.toolEffectValue.toString();
      _imagePath = c.imagePath;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _hpCtrl.dispose(); _toolValueCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final isTool    = widget.type == DeckCardType.tool;
    final isPokemon = widget.type == DeckCardType.pokemon;
    final provider  = context.read<DeckProvider>();
    final toolValue = int.tryParse(_toolValueCtrl.text) ?? 0;

    if (widget.existing != null) {
      provider.updateCard(widget.deckId, DeckCard(
        id: widget.existing!.id, name: name, type: widget.type, quantity: widget.existing!.quantity,
        description: _descCtrl.text.trim(), imagePath: _imagePath,
        pokemonType:     isPokemon ? _pkmnType     : null,
        pokemonWeakness: isPokemon ? _pkmnWeakness : null,
        pokemonHp:       isPokemon ? (int.tryParse(_hpCtrl.text) ?? 100) : null,
        pokemonStage:    isPokemon ? _pkmnStage    : null,
        preEvolutionId:  isPokemon ? _preEvolutionId : null,
        toolEffect:      isTool ? _toolEffect : ToolEffect.none,
        toolEffectValue: isTool ? toolValue   : 0,
      ));
    } else {
      provider.addCard(widget.deckId, DeckCard(
        id: _uuid.v4(), name: name, type: widget.type,
        description: _descCtrl.text.trim(), imagePath: _imagePath,
        pokemonType:     isPokemon ? _pkmnType     : null,
        pokemonWeakness: isPokemon ? _pkmnWeakness : null,
        pokemonHp:       isPokemon ? (int.tryParse(_hpCtrl.text) ?? 100) : null,
        pokemonStage:    isPokemon ? _pkmnStage    : null,
        preEvolutionId:  isPokemon ? _preEvolutionId : null,
        toolEffect:      isTool ? _toolEffect : ToolEffect.none,
        toolEffectValue: isTool ? toolValue   : 0,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPokemon = widget.type == DeckCardType.pokemon;
    final isTool    = widget.type == DeckCardType.tool;
    final typeColor = Color(widget.type.colorValue);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.type.label.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            Text(widget.existing != null ? 'EDITAR CARTA' : 'NOVA CARTA',
              style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ]),
          const SizedBox(height: 14),
          Center(child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100, height: 140,
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _imagePath != null ? typeColor.withOpacity(0.6) : AppTheme.divider)),
              clipBehavior: Clip.antiAlias,
              child: _imagePath != null
                  ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary, size: 28),
                      const SizedBox(height: 4),
                      const Text('Foto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ]),
            ),
          )),
          const SizedBox(height: 14),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome da carta'), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 8),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descrição (opcional)')),
          if (isPokemon) ...[
            const SizedBox(height: 10),
            TextField(controller: _hpCtrl, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'HP')),
            const SizedBox(height: 12),
            const Text('ESTÁGIO DE EVOLUÇÃO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(
              children: PokemonStage.values.map((stage) {
                final isSelected = _pkmnStage == stage;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _pkmnStage = stage;
                      if (stage == PokemonStage.basic) {
                        _preEvolutionId = null;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent.withOpacity(0.12) : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.divider, width: isSelected ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(
                          stage.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              if (_pkmnStage == PokemonStage.basic) return const SizedBox.shrink();
              final deck = context.read<DeckProvider>().getDeck(widget.deckId);
              final allPokemonCards = deck?.pokemonCards ?? [];
              final eligiblePreEvs = allPokemonCards.where((c) {
                if (widget.existing?.id == c.id) return false;
                if (_pkmnStage == PokemonStage.stage1 && c.stage == PokemonStage.basic) return true;
                if (_pkmnStage == PokemonStage.stage2 && c.stage == PokemonStage.stage1) return true;
                return false;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EVOLUI DE (PRÉ-EVOLUÇÃO)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.surface,
                    value: eligiblePreEvs.any((c) => c.id == _preEvolutionId) ? _preEvolutionId : null,
                    decoration: const InputDecoration(
                      labelText: 'Selecionar Pré-evolução',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Nenhuma pré-evolução'),
                      ),
                      ...eligiblePreEvs.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.pokemonHp ?? 100} HP)'))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _preEvolutionId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            const Text('TIPO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _TypeGrid(selected: _pkmnType, onSelect: (t) => setState(() { _pkmnType = t; _pkmnWeakness = t.defaultWeakness; })),
            const SizedBox(height: 12),
            const Text('FRAQUEZA', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _TypeGrid(selected: _pkmnWeakness, onSelect: (t) => setState(() => _pkmnWeakness = t), highlightColor: AppTheme.hpRed),
          ],

          // ── Efeito da ferramenta ──
          if (isTool) ...[
            const SizedBox(height: 14),
            const Text('EFEITO NO POKÉMON', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Text(
              'Só ferramentas com efeito podem ser anexadas a um Pokémon durante a batalha.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 10),
            ...ToolEffect.values.map((effect) {
              final eColor = Color(effect.colorValue);
              final isSelected = _toolEffect == effect;
              return GestureDetector(
                onTap: () => setState(() { _toolEffect = effect; if (effect == ToolEffect.none || effect == ToolEffect.immunity) _toolValueCtrl.clear(); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? eColor.withOpacity(0.12) : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? eColor : AppTheme.divider, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(_effectIcon(effect), color: isSelected ? eColor : AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(effect.label, style: TextStyle(color: isSelected ? eColor : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(effect.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ])),
                    if (isSelected) Icon(Icons.check_circle, color: eColor, size: 18),
                  ]),
                ),
              );
            }),
            // Campo de valor só para hpBonus e damageBonus
            if (_toolEffect == ToolEffect.hpBonus || _toolEffect == ToolEffect.damageBonus) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _toolValueCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _toolEffect == ToolEffect.hpBonus ? 'Quantidade de HP extra' : 'Quantidade de dano extra',
                  prefixText: '+',
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: _submit, child: Text(widget.existing != null ? 'SALVAR' : 'ADICIONAR'))),
        ]),
      ),
    );
  }
}

IconData _effectIcon(ToolEffect e) {
  switch (e) {
    case ToolEffect.none:        return Icons.block_outlined;
    case ToolEffect.hpBonus:     return Icons.favorite;
    case ToolEffect.damageBonus: return Icons.flash_on;
    case ToolEffect.immunity:    return Icons.shield_outlined;
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.22) : color.withOpacity(0.07),
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
