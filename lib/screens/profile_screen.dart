import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'budget_overview_screen.dart';
import 'categories_screen.dart';
import 'expense_model.dart';
import 'dashboard_screen.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'app_colors.dart';

/// Returns the bytes of a photo from [source], or null if none was chosen.
typedef PhotoPicker = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> _pickFromDevice(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );
  return file?.readAsBytes();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.expenses,
    this.pickPhoto = _pickFromDevice,
  });
  final List<ExpenseItem> expenses;
  final PhotoPicker pickPhoto;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _editProfile() async {
    final store = FinoraScope.of(context);
    final name = TextEditingController(text: store.name);
    final email = TextEditingController(text: store.email);
    final form = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Changes are saved for this app session.',
                  style: TextStyle(color: context.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address (optional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
                        ? null
                        : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (form.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      store.setProfile(name.text.trim(), email.text.trim());
      showMessage(context, 'Profile updated successfully');
    }
    // The sheet's route finishes its exit animation before controllers are freed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    email.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final store = FinoraScope.of(context);
    try {
      final bytes = await widget.pickPhoto(source);
      if (bytes == null || !mounted) return;
      store.setPhoto(bytes);
      showMessage(context, 'Profile picture updated');
    } catch (_) {
      if (!mounted) return;
      showMessage(
        context,
        source == ImageSource.camera
            ? 'The camera is not available on this device'
            : 'Could not open the gallery',
      );
    }
  }

  void _photoSheet() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profile picture',
              style: TextStyle(
                color: context.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.photo_camera_outlined, color: context.ink),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.photo_library_outlined, color: context.ink),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    ),
  );

  void _savingsSheet(FinoraStore store, DashboardStats stats) {
    final goal = store.savingsGoal;
    final saved = stats.remaining.clamp(0, goal).toDouble();
    final ratio = goal == 0 ? 0.0 : saved / goal;
    _sheet(
      'Savings Goal',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_lkr(saved)} of ${_lkr(goal)} saved',
            style: TextStyle(color: context.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio,
            color: emerald,
            backgroundColor: context.subtle,
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text(
            '${(ratio * 100).round()}% reached. Saved is the part of this '
            "month's budget you have not spent.",
            style: TextStyle(color: context.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final value = await showDialog<double>(
                context: context,
                builder: (_) => _GoalDialog(initial: goal),
              );
              if (value != null) store.setSavingsGoal(value);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Edit goal'),
          ),
        ],
      ),
    );
  }

  void _sheet(String title, Widget content) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = FinoraScope.of(context);
    final stats = DashboardStats(
      store.expenses,
      monthlyBudget: store.monthlyBudget,
    );
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    tooltip: 'Back to dashboard',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: context.ink),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    'My Profile',
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProfileCard(
              child: Column(
                children: [
                  SizedBox(
                    width: 98,
                    height: 98,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD1FAE5),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: context.tint,
                              backgroundImage: store.photo == null
                                  ? null
                                  : MemoryImage(store.photo!),
                              child: store.photo != null
                                  ? null
                                  : Text(
                                      store.initials,
                                      style: TextStyle(
                                        color: context.ink,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              tooltip: 'Edit profile picture',
                              style: IconButton.styleFrom(
                                backgroundColor: emerald,
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 19,
                              ),
                              onPressed: _photoSheet,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    store.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (store.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit Profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Financial Overview', trailing: stats.monthName),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Spent This Month',
                    amount: _lkr(stats.monthTotal),
                    tint: context.ink,
                    onTap: () =>
                        _open(MonthlyReportsScreen(expenses: widget.expenses)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Monthly Budget',
                    amount: _lkr(store.monthlyBudget),
                    tint: emerald,
                    onTap: () => _open(const BudgetOverviewScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.savings_outlined,
                    label: 'Savings Goal',
                    amount: _lkr(store.savingsGoal),
                    tint: const Color(0xFF6366F1),
                    onTap: () => _savingsSheet(store, stats),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _MenuGroup(
              items: [
                _MenuItem(
                  Icons.person_outline_rounded,
                  'Personal Details',
                  _editProfile,
                ),
                _MenuItem(
                  Icons.grid_view_outlined,
                  'My Categories',
                  () => _open(CategoriesScreen(expenses: widget.expenses)),
                ),
                _MenuItem(
                  Icons.tune_outlined,
                  'Budget Preferences',
                  () => _open(const BudgetOverviewScreen()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'FINORA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A little clarity. A lot more control.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0714213D),
          blurRadius: 20,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: context.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: TextStyle(color: context.muted, fontSize: 9, letterSpacing: 1),
        ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String amount;
  final Color tint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: context.subtle,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: 21),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: Text(
                label,
                style: TextStyle(
                  color: context.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  color: context.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;
  @override
  Widget build(BuildContext context) => Material(
    color: context.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          ListTile(
            onTap: items[i].onTap,
            minTileHeight: 58,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            horizontalTitleGap: 12,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: context.subtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(items[i].icon, color: context.ink, size: 19),
            ),
            title: Text(
              items[i].label,
              style: TextStyle(
                color: context.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.faint,
              size: 20,
            ),
          ),
          if (i < items.length - 1)
            Divider(height: 1, indent: 60, endIndent: 14, color: context.line),
        ],
      ],
    ),
  );
}

String _lkr(double amount) {
  final whole = amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return 'LKR $whole';
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.initial});

  final double initial;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Savings goal'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Goal amount',
            prefixText: 'LKR ',
          ),
          validator: (value) {
            final amount = double.tryParse((value ?? '').replaceAll(',', ''));
            return amount == null || !amount.isFinite || amount <= 0
                ? 'Enter a valid goal'
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                double.parse(_controller.text.replaceAll(',', '')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
