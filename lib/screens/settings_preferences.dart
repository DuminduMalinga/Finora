import 'dart:async';

import 'package:flutter/material.dart';

import '../data/finora_database.dart';
import 'finora_theme.dart';

/// The user's app settings. Changes notify listeners and, once [attach]ed to
/// a database, are saved automatically.
class SettingsPreferences extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  Color accent = emerald;

  FinoraDatabase? _db;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Loads [stored] settings and saves every later change to [database].
  void attach(FinoraDatabase database, Map<String, String> stored) {
    applyMap(stored);
    _db = database;
    addListener(_save);
  }

  void _save() {
    final db = _db;
    if (db == null) return;
    unawaited(
      db.saveSettings(toMap()).catchError((Object error, StackTrace stack) {
        debugPrint('Finora: could not save settings ($error)');
      }),
    );
  }

  Map<String, String> toMap() => {
    'theme_mode': themeMode.name,
    'accent': accent.toARGB32().toString(),
  };

  /// Applies saved values; anything missing keeps its current default.
  void applyMap(Map<String, String> values) {
    final mode = values['theme_mode'];
    for (final candidate in ThemeMode.values) {
      if (candidate.name == mode) themeMode = candidate;
    }
    final color = int.tryParse(values['accent'] ?? '');
    if (color != null) accent = Color(color);
  }

  @override
  void dispose() {
    removeListener(_save);
    super.dispose();
  }
}
