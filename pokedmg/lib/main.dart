// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/battle_provider.dart';
import 'screens/battle_screen.dart';
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
    return ChangeNotifierProvider(
      create: (_) => BattleProvider(),
      child: MaterialApp(
        title: 'PokeDMG TCG',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const BattleScreen(),
      ),
    );
  }
}
