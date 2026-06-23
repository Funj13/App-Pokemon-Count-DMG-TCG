// lib/models/pokemon.dart

enum PokemonType {
  fire,
  water,
  grass,
  electric,
  psychic,
  fighting,
  dark,
  steel,
  dragon,
  normal,
  poison,
  ghost,
}

extension PokemonTypeExtension on PokemonType {
  String get label {
    switch (this) {
      case PokemonType.fire:     return 'Fogo';
      case PokemonType.water:    return 'Água';
      case PokemonType.grass:    return 'Planta';
      case PokemonType.electric: return 'Elétrico';
      case PokemonType.psychic:  return 'Psíquico';
      case PokemonType.fighting: return 'Lutador';
      case PokemonType.dark:     return 'Sombrio';
      case PokemonType.steel:    return 'Aço';
      case PokemonType.dragon:   return 'Dragão';
      case PokemonType.normal:   return 'Normal';
      case PokemonType.poison:   return 'Veneno';
      case PokemonType.ghost:    return 'Fantasma';
    }
  }

  int get colorValue {
    switch (this) {
      case PokemonType.fire:     return 0xFFEF5350;
      case PokemonType.water:    return 0xFF42A5F5;
      case PokemonType.grass:    return 0xFF66BB6A;
      case PokemonType.electric: return 0xFFFFCA28;
      case PokemonType.psychic:  return 0xFFEC407A;
      case PokemonType.fighting: return 0xFFEF6C00;
      case PokemonType.dark:     return 0xFF5D4037;
      case PokemonType.steel:    return 0xFF78909C;
      case PokemonType.dragon:   return 0xFF5C6BC0;
      case PokemonType.normal:   return 0xFF8D8D8D;
      case PokemonType.poison:   return 0xFFAB47BC;
      case PokemonType.ghost:    return 0xFF7E57C2;
    }
  }
}

class Pokemon {
  final String id;
  String name;
  int maxHp;
  int currentHp;
  PokemonType type;
  bool isActive;

  Pokemon({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.type,
    this.isActive = false,
  }) : currentHp = maxHp;

  double get hpPercent => currentHp / maxHp;

  bool get isFainted => currentHp <= 0;

  Pokemon copyWith({
    String? name,
    int? maxHp,
    int? currentHp,
    PokemonType? type,
    bool? isActive,
  }) {
    return Pokemon(
      id: id,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    )..currentHp = currentHp ?? this.currentHp;
  }
}
