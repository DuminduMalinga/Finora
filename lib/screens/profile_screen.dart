import 'package:flutter/material.dart';

import 'budget_overview_screen.dart';
import 'categories_screen.dart';
import 'expense_model.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';

const _gray = Color(0xFFF5F7FA);
const _subtle = Color(0xFF64748B);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.expenses});
  final List<ExpenseItem> expenses;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Alex Morgan';
  String _email = 'alex.morgan@email.com';
  bool _usePhoto = true;
  bool _expenseAlerts = true;
  bool _budgetAlerts = true;
  bool _monthlySummary = false;

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _name);
    final email = TextEditingController(text: _email);
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
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Changes are saved for this app session.',
                  style: TextStyle(color: _subtle),
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
                    labelText: 'Email address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch((value ?? '').trim())
                      ? null
                      : 'Enter a valid email',
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
      setState(() {
        _name = name.text.trim();
        _email = email.text.trim();
      });
      showMessage(context, 'Profile updated successfully');
    }
    // The sheet's route finishes its exit animation before controllers are freed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    email.dispose();
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
                style: const TextStyle(
                  color: navy,
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

  void _notifications() => _sheet(
    'Notification Preferences',
    StatefulBuilder(
      builder: (context, update) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose what you see in Spendly. Preferences apply to this session.',
            style: TextStyle(color: _subtle),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Expense reminders'),
            value: _expenseAlerts,
            onChanged: (value) => update(() => _expenseAlerts = value),
            activeTrackColor: emerald,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budget alerts'),
            value: _budgetAlerts,
            onChanged: (value) => update(() => _budgetAlerts = value),
            activeTrackColor: emerald,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Monthly summary'),
            value: _monthlySummary,
            onChanged: (value) => update(() => _monthlySummary = value),
            activeTrackColor: emerald,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  tooltip: 'Back to dashboard',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: navy),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Notifications',
                onPressed: () => _sheet(
                  'Notifications',
                  const Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 40,
                        color: emerald,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'You’re all caught up',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your spending updates will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _gray,
                  foregroundColor: navy,
                ),
                icon: const Icon(Icons.notifications_none_rounded),
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
                            backgroundColor: paleBlue,
                            backgroundImage: _usePhoto
                                ? const AssetImage(
                                    'assets/images/alex_morgan.jpg',
                                  )
                                : null,
                            child: _usePhoto
                                ? null
                                : Text(
                                    _name
                                        .trim()
                                        .split(RegExp(r'\s+'))
                                        .take(2)
                                        .map((word) => word[0])
                                        .join()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: navy,
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
                            onPressed: () => _sheet(
                              'Profile picture',
                              Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.portrait_outlined,
                                    ),
                                    title: const Text('Use sample portrait'),
                                    onTap: () {
                                      setState(() => _usePhoto = true);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.account_circle_outlined,
                                    ),
                                    title: const Text('Use my initials'),
                                    onTap: () {
                                      setState(() => _usePhoto = false);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _subtle, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF047857),
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Personal Account',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit Profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
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
          const _SectionTitle('Financial Overview', trailing: 'DEMO'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Total Expenses',
                  amount: 'LKR 42,850',
                  tint: navy,
                  onTap: () =>
                      _open(MonthlyReportsScreen(expenses: widget.expenses)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Monthly Budget',
                  amount: 'LKR 75,000',
                  tint: emerald,
                  onTap: () => _open(const BudgetOverviewScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.savings_outlined,
                  label: 'Savings Goal',
                  amount: 'LKR 150,000',
                  tint: const Color(0xFF6366F1),
                  onTap: () => _sheet(
                    'Savings Goal',
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency fund',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('LKR 60,000 of LKR 150,000 saved'),
                        SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: 0.4,
                          color: emerald,
                          backgroundColor: _gray,
                          minHeight: 8,
                        ),
                        SizedBox(height: 10),
                        Text('40% of your sample goal reached. Keep going!'),
                      ],
                    ),
                  ),
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
                Icons.credit_card_outlined,
                'Manage Payment Methods',
                () => _sheet(
                  'Manage Payment Methods',
                  const Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.credit_card, color: navy),
                        title: Text('Visa •••• 4832'),
                        subtitle: Text('Sample card • Default payment method'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.payments_outlined, color: emerald),
                        title: Text('Cash'),
                        subtitle: Text('Available for expense tracking'),
                      ),
                    ],
                  ),
                ),
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
          const _SectionTitle('Account'),
          const SizedBox(height: 12),
          _MenuGroup(
            items: [
              _MenuItem(
                Icons.lock_outline_rounded,
                'Change Password',
                () => _sheet(
                  'Change Password',
                  const Text(
                    'You’re viewing a demo profile. Password changes will be available when an account sign-in service is connected.',
                  ),
                ),
              ),
              _MenuItem(
                Icons.shield_outlined,
                'Privacy & Security',
                () => _sheet(
                  'Privacy & Security',
                  const Text(
                    'This demo keeps profile edits in memory for the current session. No bank connection or cloud profile storage is configured.',
                  ),
                ),
              ),
              _MenuItem(
                Icons.notifications_none_rounded,
                'Notification Preferences',
                _notifications,
              ),
              _MenuItem(
                Icons.link_rounded,
                'Connected Accounts',
                () => _sheet(
                  'Connected Accounts',
                  const Column(
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 40,
                        color: emerald,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No accounts connected',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can track expenses manually. Bank connections are not available in this demo.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'SPENDLY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A little clarity. A lot more control.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtle, fontSize: 11),
          ),
        ],
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDF0F4)),
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
          style: const TextStyle(
            color: navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(color: _subtle, fontSize: 9, letterSpacing: 1),
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
    color: _gray,
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
                style: const TextStyle(
                  color: _subtle,
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
                style: const TextStyle(
                  color: navy,
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
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFEDF0F4)),
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
                color: _gray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(items[i].icon, color: navy, size: 19),
            ),
            title: Text(
              items[i].label,
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          if (i < items.length - 1)
            const Divider(
              height: 1,
              indent: 60,
              endIndent: 14,
              color: Color(0xFFF0F2F5),
            ),
        ],
      ],
    ),
  );
}
