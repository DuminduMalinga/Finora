import 'package:flutter/material.dart';

import 'finora_theme.dart';
import 'settings_preferences.dart';
import 'app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onBack,
  });
  final SettingsPreferences preferences;
  final VoidCallback onBack;

  void _info(BuildContext context, String title, String message) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsDetailPage(title: title, message: message),
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
        onSurface: dark ? const Color(0xFFF1F5F9) : context.ink,
        surfaceContainerLow: dark ? const Color(0xFF242C3D) : context.subtle,
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
                      ],
                    ),
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
                      'A little clarity. A lot more control.\n\nFinora helps you track expenses, plan budgets, and understand your monthly spending. Your data is stored on this device.',
                    ),
                  ),
                  const _SettingRow(
                    icon: Icons.mobile_friendly_outlined,
                    title: 'App Version',
                    value: '1.0.0',
                  ),
                ],
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
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
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
