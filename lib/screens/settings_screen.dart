import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'expense_model.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'settings_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.expenses,
    required this.onBack,
    required this.onClearData,
    required this.onRestore,
  });
  final SettingsPreferences preferences;
  final List<ExpenseItem> expenses;
  final VoidCallback onBack;
  final VoidCallback onClearData;
  final ValueChanged<List<ExpenseItem>> onRestore;

  Future<void> _choose(
    BuildContext context,
    String title,
    List<String> values,
    String selected,
    ValueChanged<String> changed,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: values
            .map(
              (value) => SimpleDialogOption(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                onPressed: () => Navigator.pop(context, value),
                child: Row(
                  children: [
                    Expanded(child: Text(value)),
                    if (value == selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: preferences.accent,
                        size: 21,
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) preferences.update(() => changed(result));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: coral, size: 32),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: coral,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  void _info(BuildContext context, String title, String message) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsDetailPage(title: title, message: message),
      ),
    );
  }

  void _export(BuildContext context) {
    String quote(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = [
      'Title,Category,Amount,Date,Notes',
      ...expenses.map(
        (e) => [
          e.title,
          e.category,
          e.amount,
          e.date,
          e.notes,
        ].map(quote).join(','),
      ),
    ].join('\r\n');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export Expense Data',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('${expenses.length} transactions • CSV format'),
            const SizedBox(height: 8),
            const Text(
              'Copy your expense data to paste into a spreadsheet or save as a CSV file.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy CSV'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (!context.mounted) return;
                Navigator.pop(context);
                showMessage(context, 'Expense CSV copied to clipboard');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _backup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: preferences,
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: const Text('Backup & Restore')),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: preferences.accent,
                  size: 52,
                ),
                const SizedBox(height: 24),
                const Text(
                  'A little peace of mind',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a temporary snapshot of your expenses. This preview stores it only until the app closes; it is not a cloud backup.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    preferences.update(
                      () => preferences.backup = List.of(expenses),
                    );
                    showMessage(context, 'Session backup created');
                  },
                  child: const Text('Create session backup'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: preferences.backup == null
                      ? null
                      : () async {
                          final confirmed = await _confirm(
                            context,
                            title: 'Restore backup?',
                            message:
                                'Replace your current expenses with the saved session snapshot?',
                            action: 'Restore',
                          );
                          if (!confirmed || !context.mounted) return;
                          onRestore(List.of(preferences.backup!));
                          showMessage(context, 'Expenses restored');
                        },
                  child: const Text('Restore session backup'),
                ),
                const SizedBox(height: 16),
                Text(
                  preferences.backup == null
                      ? 'No session backup yet.'
                      : '${preferences.backup!.length} expenses in your session backup.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final theme = Theme.of(context);
      final dark = theme.brightness == Brightness.dark;
      final colors = theme.colorScheme.copyWith(
        onSurface: dark ? const Color(0xFFF1F5F9) : navy,
        surfaceContainerLow: dark
            ? const Color(0xFF242C3D)
            : const Color(0xFFF5F7FA),
      );
      final muted = colors.onSurfaceVariant;
      final accent = preferences.accent;
      return Theme(
        data: theme.copyWith(
          colorScheme: colors,
          textTheme: theme.textTheme.apply(
            bodyColor: colors.onSurface,
            displayColor: colors.onSurface,
          ),
        ),
        child: Scaffold(
          backgroundColor: colors.surface,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to Home',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Customize your Finora experience.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const _SectionHeading('Appearance', Icons.palette_outlined),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ThemeChoice(
                              label: 'Light',
                              icon: Icons.light_mode_outlined,
                              selected:
                                  preferences.themeMode == ThemeMode.light,
                              accent: accent,
                              onTap: () => preferences.update(
                                () => preferences.themeMode = ThemeMode.light,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ThemeChoice(
                              label: 'Dark',
                              icon: Icons.dark_mode_outlined,
                              selected: preferences.themeMode == ThemeMode.dark,
                              accent: accent,
                              onTap: () => preferences.update(
                                () => preferences.themeMode = ThemeMode.dark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ThemeChoice(
                              label: 'System Default',
                              icon: Icons.brightness_auto_outlined,
                              selected:
                                  preferences.themeMode == ThemeMode.system,
                              accent: accent,
                              onTap: () => preferences.update(
                                () => preferences.themeMode = ThemeMode.system,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Accent Color',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            for (final color in [
                              emerald,
                              const Color(0xFF6366F1),
                              const Color(0xFF0EA5E9),
                              const Color(0xFFF59E0B),
                            ])
                              Semantics(
                                selected: accent == color,
                                button: true,
                                child: IconButton(
                                  tooltip: {
                                    emerald: 'Emerald',
                                    const Color(0xFF6366F1): 'Indigo',
                                    const Color(0xFF0EA5E9): 'Sky',
                                    const Color(0xFFF59E0B): 'Amber',
                                  }[color],
                                  onPressed: () => preferences.update(
                                    () => preferences.accent = color,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 44,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  icon: Container(
                                    width: 27,
                                    height: 27,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: accent == color
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 17,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: accent,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SPENT THIS MONTH',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 9,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LKR ${MonthlyReportData(expenses, DateTime(DateTime.now().year, DateTime.now().month)).total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.check_circle_rounded,
                                color: accent,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const _SectionHeading('Preferences', Icons.tune_outlined),
              _SettingsCard(
                children: [
                  _SettingRow(
                    icon: Icons.payments_outlined,
                    title: 'Currency',
                    subtitle: preferences.currency,
                    onTap: () => _choose(
                      context,
                      'Currency',
                      [
                        'LKR (Sri Lankan Rupee)',
                        'USD (US Dollar)',
                        'EUR (Euro)',
                        'GBP (British Pound)',
                      ],
                      preferences.currency,
                      (v) => preferences.currency = v,
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    value: preferences.language,
                    onTap: () => _choose(
                      context,
                      'Language',
                      ['English', 'Sinhala', 'Tamil'],
                      preferences.language,
                      (v) => preferences.language = v,
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.calendar_view_week_outlined,
                    title: 'First Day of Week',
                    value: preferences.firstDay,
                    onTap: () => _choose(
                      context,
                      'First Day of Week',
                      ['Monday', 'Sunday', 'Saturday'],
                      preferences.firstDay,
                      (v) => preferences.firstDay = v,
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.date_range_outlined,
                    title: 'Date Format',
                    value: preferences.dateFormat,
                    onTap: () => _choose(
                      context,
                      'Date Format',
                      ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                      preferences.dateFormat,
                      (v) => preferences.dateFormat = v,
                    ),
                  ),
                ],
              ),
              const _SectionHeading(
                'Notifications',
                Icons.notifications_none_rounded,
              ),
              _SettingsCard(
                children: [
                  _ToggleRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Expense Reminders',
                    value: preferences.expenseReminders,
                    accent: accent,
                    onChanged: (v) => preferences.update(
                      () => preferences.expenseReminders = v,
                    ),
                  ),
                  _ToggleRow(
                    icon: Icons.today_outlined,
                    title: 'Daily Spending Summary',
                    value: preferences.dailySummary,
                    accent: accent,
                    onChanged: (v) =>
                        preferences.update(() => preferences.dailySummary = v),
                  ),
                  _ToggleRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Budget Limit Alerts',
                    value: preferences.budgetAlerts,
                    accent: accent,
                    onChanged: (v) =>
                        preferences.update(() => preferences.budgetAlerts = v),
                  ),
                  _ToggleRow(
                    icon: Icons.bar_chart_rounded,
                    title: 'Weekly Financial Reports',
                    value: preferences.weeklyReports,
                    accent: accent,
                    onChanged: (v) =>
                        preferences.update(() => preferences.weeklyReports = v),
                  ),
                ],
              ),
              const _SectionHeading('Security', Icons.shield_outlined),
              _SettingsCard(
                children: [
                  _SettingRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    onTap: () => _info(
                      context,
                      'Change Password',
                      'Password changes are available with a signed-in account. This local preview is not connected to an authentication service.',
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Enable Biometric Authentication',
                    onTap: () => _info(
                      context,
                      'Biometric Authentication',
                      'Use your device’s fingerprint or face recognition to unlock Finora. Device authentication is not enabled in this preview.',
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.phonelink_lock_outlined,
                    title: 'App Lock',
                    value: 'Off',
                    onTap: () => _info(
                      context,
                      'App Lock',
                      'An app lock can protect your financial information when you leave Finora. PIN and biometric enrollment are not configured in this preview, so the app is currently unlocked.',
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Privacy Settings',
                    onTap: () => _info(
                      context,
                      'Privacy Settings',
                      'Your profile and settings changes stay in this app session. No analytics, bank connection, or cloud account is configured. Avoid entering sensitive information into this preview.',
                    ),
                  ),
                ],
              ),
              const _SectionHeading('Data Management', Icons.storage_outlined),
              _SettingsCard(
                children: [
                  _SettingRow(
                    icon: Icons.file_download_outlined,
                    title: 'Export Expense Data',
                    onTap: () => _export(context),
                  ),
                  _SettingRow(
                    icon: Icons.cloud_sync_outlined,
                    title: 'Backup & Restore',
                    onTap: () => _backup(context),
                  ),
                  _SettingRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Clear App Data',
                    destructive: true,
                    onTap: () async {
                      if (!await _confirm(
                            context,
                            title: 'Clear app data?',
                            message:
                                'This removes all expense transactions from this app session. Export your expenses or create a session backup first. This cannot be undone without a backup.',
                            action: 'Clear Data',
                          ) ||
                          !context.mounted) {
                        return;
                      }
                      onClearData();
                      showMessage(context, 'Expense data cleared');
                    },
                  ),
                ],
              ),
              const _SectionHeading('About', Icons.info_outline_rounded),
              _SettingsCard(
                children: [
                  _SettingRow(
                    icon: Icons.auto_awesome_outlined,
                    title: 'About Finora',
                    onTap: () => _info(
                      context,
                      'About Finora',
                      'A little clarity. A lot more control.\n\nFinora helps you track expenses, plan budgets, and understand your monthly spending.',
                    ),
                  ),
                  const _SettingRow(
                    icon: Icons.mobile_friendly_outlined,
                    title: 'App Version',
                    value: '1.0.0',
                  ),
                  _SettingRow(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _info(
                      context,
                      'Privacy Policy',
                      'This is a design preview, not a published privacy policy. No production data service is connected. A complete policy must be provided before an account service is launched.',
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _info(
                      context,
                      'Terms & Conditions',
                      'This is a local Finora preview. Published terms for a production service are not available in this version.',
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Send Feedback',
                    onTap: () => _info(
                      context,
                      'Send Feedback',
                      'We’d love to hear your ideas. Feedback delivery is not connected in this local preview.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  if (!await _confirm(
                        context,
                        title: 'Log out of Finora?',
                        message: 'Are you sure you want to log out?',
                        action: 'Logout',
                      ) ||
                      !context.mounted) {
                    return;
                  }
                  _info(
                    context,
                    'Logout',
                    'This preview has no signed-in account. Your local expense session is still available.',
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  if (!await _confirm(
                        context,
                        title: 'Delete account permanently?',
                        message:
                            'Deleting a real Finora account would permanently remove its profile and financial data. This action cannot be undone.',
                        action: 'Delete Account',
                      ) ||
                      !context.mounted) {
                    return;
                  }
                  _info(
                    context,
                    'Delete Account',
                    'No remote account is connected to delete. To remove local expenses, use Clear App Data.',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: coral,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Delete Account'),
              ),
              const SizedBox(height: 16),
              Text(
                'Finora 1.0.0 • Local preview\nPreferences apply to this session. Currency and language selections are previews; recorded amounts remain in LKR.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: muted, height: 1.6),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.shield_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(height: 1.6)),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.icon);
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0514213D),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  indent: 54,
                  endIndent: 14,
                  color: colors.outlineVariant.withValues(alpha: 0.35),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = destructive ? coral : colors.onSurface;
    return ListTile(
      onTap: onTap,
      minTileHeight: 62,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, size: 20, color: foreground),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    value: value,
    onChanged: onChanged,
    activeTrackColor: accent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    secondary: Icon(icon, size: 20),
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: '$label theme',
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? accent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
