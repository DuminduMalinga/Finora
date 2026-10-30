import 'package:flutter/material.dart';

import 'screens/finora_screens.dart';
import 'screens/finora_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: FinoraTheme.theme,
      home: const FinoraShell(),
    );
  }
}
