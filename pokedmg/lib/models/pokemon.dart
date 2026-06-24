// lib/models/pokemon.dart

import 'dart:io';
import 'tool_card.dart';

enum PokemonType {
  fire, water, grass, electric, psychic,
  fighting, dark, steel, dragon, normal, poison, ghost, colorless,
}

enum PokemonPosition { active, bench }

enum PokemonStage { basic, stage1, stage2 }

extension PokemonStageExtension on PokemonStage {
  String get label {
    switch (this) {
      case PokemonStage.basic:  return 'Básico';
      case PokemonStage.stage1: return 'Estágio 1';
      case PokemonStage.stage2: return 'Estágio 2';
    }
  }

  bool canEvolveTo(PokemonStage next) {
    if (this == PokemonStage.basic && next == PokemonStage.stage1) return true;
    if (this == PokemonStage.stage1 && next == PokemonStage.stage2) return true;
    return false;
  }
}

extension PokemonTypeExtension on PokemonType {
  String get label {
    switch (this) {
      case PokemonType.fire:      return 'Fogo';
      case PokemonType.water:     return 'Água';
      case PokemonType.grass:     return 'Planta';
      case PokemonType.electric:  return 'Elétrico';
      case PokemonType.psychic:   return 'Psíquico';
      case PokemonType.fighting:  return 'Lutador';
      case PokemonType.dark:      return 'Sombrio';
      case PokemonType.steel:     return 'Aço';
      case PokemonType.dragon:    return 'Dragão';
      case PokemonType.normal:    return 'Normal';
      case PokemonType.poison:    return 'Veneno';
      case PokemonType.ghost:     return 'Fantasma';
      case PokemonType.colorless: return 'Incolor';
    }
  }

  int get colorValue {
    switch (this) {
      case PokemonType.fire:      return 0xFFEF5350;
      case PokemonType.water:     return 0xFF42A5F5;
      case PokemonType.grass:     return 0xFF66BB6A;
      case PokemonType.electric:  return 0xFFFFCA28;
      case PokemonType.psychic:   return 0xFFEC407A;
      case PokemonType.fighting:  return 0xFFEF6C00;
      case PokemonType.dark:      return 0xFF5D4037;
      case PokemonType.steel:     return 0xFF78909C;
      case PokemonType.dragon:    return 0xFF5C6BC0;
      case PokemonType.normal:    return 0xFF8D8D8D;
      case PokemonType.poison:    return 0xFFAB47BC;
      case PokemonType.ghost:     return 0xFF7E57C2;
      case PokemonType.colorless: return 0xFFBDBDBD;
    }
  }

  PokemonType get defaultWeakness {
    switch (this) {
      case PokemonType.fire:      return PokemonType.water;
      case PokemonType.water:     return PokemonType.electric;
      case PokemonType.grass:     return PokemonType.fire;
      case PokemonType.electric:  return PokemonType.fighting;
      case PokemonType.psychic:   return PokemonType.dark;
      case PokemonType.fighting:  return PokemonType.psychic;
      case PokemonType.dark:      return PokemonType.fighting;
      case PokemonType.steel:     return PokemonType.fire;
      case PokemonType.dragon:    return PokemonType.dragon;
      case PokemonType.normal:    return PokemonType.fighting;
      case PokemonType.poison:    return PokemonType.psychic;
      case PokemonType.ghost:     return PokemonType.dark;
      case PokemonType.colorless: return PokemonType.fighting;
    }
  }
}

class Pokemon {
  final String id;
  String name;
  int baseMaxHp;
  int currentHp;
  PokemonType type;
  PokemonType weakness;
  PokemonPosition position;
  String? imagePath;
  List<ToolCard> tools;
  final PokemonStage stage;
  final String? deckCardId; // ID da carta correspondente no deck

  Pokemon({
    required this.id,
    required this.name,
    required this.baseMaxHp,
    required this.type,
    PokemonType? weakness,
    this.position = PokemonPosition.bench,
    this.imagePath,
    List<ToolCard>? tools,
    this.stage = PokemonStage.basic,
    this.deckCardId,
  })  : currentHp = baseMaxHp,
        weakness = weakness ?? type.defaultWeakness,
        tools = tools ?? [];

  /// HP máximo real = base + bônus de ferramentas
  int get maxHp => baseMaxHp + tools
      .where((t) => t.effect == ToolEffect.hpBonus)
      .fold(0, (sum, t) => sum + t.value);

  /// Bônus de dano de ferramentas
  int get damageBonus => tools
      .where((t) => t.effect == ToolEffect.damageBonus)
      .fold(0, (sum, t) => sum + t.value);

  /// Pokémon com imunidade não recebe efeitos externos
  bool get hasImmunity => tools.any((t) => t.effect == ToolEffect.immunity);

  double get hpPercent => maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0;
  bool get isFainted => currentHp <= 0;
  bool get isActive => position == PokemonPosition.active;
  File? get imageFile => imagePath != null ? File(imagePath!) : null;

  void addTool(ToolCard tool) {
    tools.add(tool);
    // Ao ganhar HP extra, aumenta o HP atual proporcionalmente
    if (tool.effect == ToolEffect.hpBonus) currentHp += tool.value;
  }

  void removeTool(String toolId) {
    final tool = tools.firstWhere((t) => t.id == toolId, orElse: () => ToolCard(id:'',name:'',description:'',effect:ToolEffect.none));
    if (tool.id.isEmpty) return;
    if (tool.effect == ToolEffect.hpBonus) {
      currentHp = (currentHp - tool.value).clamp(0, maxHp - tool.value);
    }
    tools.removeWhere((t) => t.id == toolId);
  }

  Pokemon copyWith({
    String? name,
    int? baseMaxHp,
    int? currentHp,
    PokemonType? type,
    PokemonType? weakness,
    PokemonPosition? position,
    String? imagePath,
    List<ToolCard>? tools,
    bool clearImage = false,
    PokemonStage? stage,
    String? deckCardId,
    bool clearDeckCardId = false,
  }) {
    final p = Pokemon(
      id: id,
      name: name ?? this.name,
      baseMaxHp: baseMaxHp ?? this.baseMaxHp,
      type: type ?? this.type,
      weakness: weakness ?? this.weakness,
      position: position ?? this.position,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      tools: tools ?? List.from(this.tools),
      stage: stage ?? this.stage,
      deckCardId: clearDeckCardId ? null : (deckCardId ?? this.deckCardId),
    );
    p.currentHp = currentHp ?? this.currentHp;
    return p;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseMaxHp': baseMaxHp,
    'currentHp': currentHp,
    'type': type.index,
    'weakness': weakness.index,
    'position': position.index,
    'imagePath': imagePath,
    'tools': tools.map((t) => t.toJson()).toList(),
    'stage': stage.index,
    'deckCardId': deckCardId,
  };

  factory Pokemon.fromJson(Map<String, dynamic> j) {
    final p = Pokemon(
      id: j['id'],
      name: j['name'],
      baseMaxHp: j['baseMaxHp'],
      type: PokemonType.values[j['type']],
      weakness: PokemonType.values[j['weakness']],
      position: PokemonPosition.values[j['position']],
      imagePath: j['imagePath'],
      tools: (j['tools'] as List?)?.map((t) => ToolCard.fromJson(t)).toList() ?? [],
      stage: j['stage'] != null ? PokemonStage.values[j['stage']] : PokemonStage.basic,
      deckCardId: j['deckCardId'],
    );
    p.currentHp = j['currentHp'] ?? j['baseMaxHp'];
    return p;
  }
}
