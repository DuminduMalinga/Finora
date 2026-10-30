import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'finora_theme.dart';

/// Session settings for the local app preview.
class SettingsPreferences extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  Color accent = emerald;
  String currency = 'LKR (Sri Lankan Rupee)';
  String language = 'English';
  String firstDay = 'Monday';
  String dateFormat = 'DD/MM/YYYY';
  bool expenseReminders = true;
  bool dailySummary = false;
  bool budgetAlerts = true;
  bool weeklyReports = false;
  List<ExpenseItem>? backup;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
