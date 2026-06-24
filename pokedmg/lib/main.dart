// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/battle_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/history_provider.dart';
import 'screens/battle_screen.dart';
import 'screens/deck_list_screen.dart';
import 'screens/history_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PokeDmgApp());
}

class PokeDmgApp extends StatelessWidget {
  const PokeDmgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BattleProvider()..load()),
        ChangeNotifierProvider(create: (_) => DeckProvider()..load()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
      ],
      child: MaterialApp(
        title: 'PokeDMG TCG',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const _RootNav(),
      ),
    );
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav();
  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  static const _screens = [
    BattleScreen(),
    DeckListScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.accent.withOpacity(0.2),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon_outlined),
            selectedIcon: Icon(Icons.catching_pokemon, color: AppTheme.accent),
            label: 'Batalha',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style, color: AppTheme.accent),
            label: 'Decks',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events, color: AppTheme.accent),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
