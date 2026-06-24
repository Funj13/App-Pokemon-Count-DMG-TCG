// lib/models/tool_card.dart

/// Efeitos que uma carta de ferramenta pode ter no Pokémon ao qual está anexada.
/// Apenas cartas com efeito definido (não `none`) podem ser anexadas a um Pokémon.
enum ToolEffect {
  none,           // Sem efeito permanente — não pode ser anexada
  hpBonus,        // Aumenta o HP máximo do Pokémon
  damageBonus,    // Aumenta o dano causado pelo Pokémon
  immunity,       // Impede que efeitos sejam aplicados ao Pokémon
}

extension ToolEffectExt on ToolEffect {
  String get label {
    switch (this) {
      case ToolEffect.none:        return 'Sem efeito';
      case ToolEffect.hpBonus:     return '+HP';
      case ToolEffect.damageBonus: return '+Dano';
      case ToolEffect.immunity:    return 'Imunidade';
    }
  }

  String get description {
    switch (this) {
      case ToolEffect.none:        return 'Carta sem efeito permanente no Pokémon';
      case ToolEffect.hpBonus:     return 'Aumenta o HP máximo do Pokémon';
      case ToolEffect.damageBonus: return 'Aumenta o dano causado pelo Pokémon';
      case ToolEffect.immunity:    return 'Impede que efeitos sejam aplicados ao Pokémon';
    }
  }

  bool get canAttach => this != ToolEffect.none;

  int get colorValue {
    switch (this) {
      case ToolEffect.none:        return 0xFF616161;
      case ToolEffect.hpBonus:     return 0xFF4CAF50;
      case ToolEffect.damageBonus: return 0xFFE63946;
      case ToolEffect.immunity:    return 0xFF7E57C2;
    }
  }
}

class ToolCard {
  final String id;
  final String name;
  final String description;
  final ToolEffect effect;
  final int value; // valor numérico para hpBonus (+HP) e damageBonus (+DMG); 0 para outros

  ToolCard({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    this.value = 0,
  });

  ToolCard copyWith({
    String? name,
    String? description,
    ToolEffect? effect,
    int? value,
  }) => ToolCard(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    effect: effect ?? this.effect,
    value: value ?? this.value,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'effect': effect.index,
    'value': value,
  };

  factory ToolCard.fromJson(Map<String, dynamic> j) => ToolCard(
    id: j['id'],
    name: j['name'],
    description: j['description'] ?? '',
    effect: ToolEffect.values[j['effect']],
    value: j['value'] ?? 0,
  );
}
