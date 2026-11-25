import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'expense_history_screen.dart';
import 'expense_actions.dart';
import 'expense_details_screen.dart';
import 'budget_overview_screen.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'app_colors.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _rs(double amount) => 'LKR ${formatAmount(amount)}';

/// Totals shown on Home, derived from the live expense list.
class DashboardStats {
  DashboardStats(
    List<ExpenseItem> expenses, {
    required this.monthlyBudget,
    DateTime? now,
  }) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final lastMonday = monday.subtract(const Duration(days: 7));
    final previousMonth = DateTime(today.year, today.month - 1);
    for (final expense in expenses) {
      final date = MonthlyReportData.parseDate(expense.date, today);
      final amount = parseAmount(expense.amount);
      if (date == null || amount == null || !amount.isFinite || amount <= 0) {
        continue;
      }
      final day = DateUtils.dateOnly(date);
      if (day.year == previousMonth.year && day.month == previousMonth.month) {
        previousMonthTotal += amount;
      }
      if (day.year == today.year && day.month == today.month) {
        monthTotal += amount;
        final entry = _categories[expense.category];
        _categories[expense.category] = (
          (entry?.$1 ?? 0) + amount,
          entry?.$2 ?? expense,
        );
      }
      final offset = day.difference(monday).inDays;
      if (offset >= 0 && offset < 7) {
        week[offset] += amount;
      } else if (day.difference(lastMonday).inDays >= 0 && offset < 0) {
        previousWeekTotal += amount;
      }
    }
    todayIndex = today.weekday - 1;
    monthName = '${_monthNames[today.month - 1]} ${today.year}';
  }

  final double monthlyBudget;
  double monthTotal = 0;
  double previousMonthTotal = 0;
  double previousWeekTotal = 0;
  final List<double> week = List.filled(7, 0);
  final Map<String, (double, ExpenseItem)> _categories = {};
  late final int todayIndex;
  late final String monthName;

  double get weekTotal => week.fold(0, (a, b) => a + b);
  double get remaining => monthlyBudget - monthTotal;
  double get usedRatio => (monthTotal / monthlyBudget).clamp(0, 1);

  /// Percent change against the previous period, or null with no baseline.
  static double? change(double current, double previous) =>
      previous > 0 ? (current - previous) / previous * 100 : null;

  List<(String, double, ExpenseItem)> get topCategories {
    final list =
        _categories.entries.map((e) => (e.key, e.value.$1, e.value.$2)).toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(3).toList();
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.onAddExpense,
  });

  final List<ExpenseItem> expenses;
  final VoidCallback onAddExpense;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ExpenseItem> get expenses => widget.expenses;

  @override
  Widget build(BuildContext context) {
    final store = FinoraScope.of(context);
    final stats = DashboardStats(expenses, monthlyBudget: store.monthlyBudget);
    final alertCount = buildNotifications(
      expenses: expenses,
      monthlyBudget: store.monthlyBudget,
      limits: store.categoryLimits,
    ).length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _HomeHeader(
                name: store.name,
                initials: store.initials,
                photo: store.photo,
                alertCount: alertCount,
                onProfile: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(expenses: expenses),
                  ),
                ),
                onNotifications: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              MonthSelector(
                label: stats.monthName,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MonthlyReportsScreen(expenses: expenses),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BalanceCard(
                stats: stats,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BudgetOverviewScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              QuickActions(
                items: [
                  (Icons.add_rounded, 'Add expense', widget.onAddExpense),
                  (
                    Icons.format_list_bulleted_rounded,
                    'History',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ExpenseHistoryScreen(expenses: expenses),
                      ),
                    ),
                  ),
                  (
                    Icons.account_balance_wallet_outlined,
                    'Budget',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BudgetOverviewScreen(),
                      ),
                    ),
                  ),
                  (
                    Icons.more_horiz_rounded,
                    'More',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MonthlyReportsScreen(expenses: expenses),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Spending overview',
                action: 'This week',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MonthlyReportsScreen(expenses: expenses),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SpendingChart(stats: stats),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Where your money goes',
                action: 'See all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MonthlyReportsScreen(expenses: expenses),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CategoryBreakdown(stats: stats),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Recent transactions',
                action: 'View all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExpenseHistoryScreen(expenses: expenses),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (expenses.isEmpty) const _EmptyTransactions(),
              ...expenses
                  .take(3)
                  .map(
                    (expense) => ExpenseTile(
                      expense: expense,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExpenseDetailsScreen(
                            expense: expense,
                            onUpdated: (updated) =>
                                store.replaceExpense(expense, updated),
                            onDeleted: () => store.removeExpense(expense),
                          ),
                        ),
                      ),
                    ),
                  ),
            ]),
          ),
        ),
      ],
    );
  }
}

String _greeting(int hour) => hour < 12
    ? 'Good morning'
    : hour < 17
    ? 'Good afternoon'
    : 'Good evening';

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, color: context.ink, size: 34),
        SizedBox(height: 10),
        Text(
          'No expenses yet',
          style: TextStyle(
            color: context.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tap “Add expense” to record your first one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted, fontSize: 12.5),
        ),
      ],
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.initials,
    required this.photo,
    required this.alertCount,
    required this.onNotifications,
    required this.onProfile,
  });

  final String name;
  final String initials;
  final Uint8List? photo;
  final int alertCount;

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Open profile',
          onPressed: onProfile,
          padding: EdgeInsets.zero,
          icon: CircleAvatar(
            radius: 23,
            backgroundColor: navy,
            backgroundImage: photo == null ? null : MemoryImage(photo!),
            child: photo != null
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      color: emerald,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(DateTime.now().hour)},',
                style: TextStyle(color: context.muted, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: alertCount == 0
              ? 'Notifications'
              : 'Notifications ($alertCount)',
          onPressed: onNotifications,
          style: IconButton.styleFrom(backgroundColor: context.surface),
          icon: Badge(
            isLabelVisible: alertCount > 0,
            label: Text('$alertCount'),
            backgroundColor: coral,
            child: Icon(Icons.notifications_none_rounded, color: context.ink),
          ),
        ),
      ],
    );
  }
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, color: context.ink, size: 20),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: context.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({
    required this.percent,
    required this.background,
    required this.upColor,
    required this.downColor,
    this.showIcon = false,
  });

  final double? percent;
  final Color background;
  final Color upColor;
  final Color downColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const SizedBox.shrink();
    final up = value > 0;
    final color = up ? upColor : downColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '${up ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.stats, this.onTap});

  final DashboardStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final over = stats.remaining < 0;
    final whole = formatAmount(stats.monthTotal).split('.');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: context.hero,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Spent in ${stats.monthName.split(' ').first}',
                  style: const TextStyle(
                    color: Color(0xFFC9D4BC),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _ChangeBadge(
                  percent: DashboardStats.change(
                    stats.monthTotal,
                    stats.previousMonthTotal,
                  ),
                  background: emerald,
                  upColor: navy,
                  downColor: navy,
                  showIcon: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'LKR ${whole.first}'),
                  if (whole.length > 1)
                    TextSpan(
                      text: '.${whole.last}',
                      style: const TextStyle(
                        color: Color(0xFF8E9B80),
                        fontSize: 20,
                      ),
                    ),
                ],
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: stats.usedRatio,
                minHeight: 10,
                backgroundColor: const Color(0xFF2A322A),
                valueColor: AlwaysStoppedAnimation(over ? coral : emerald),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(stats.usedRatio * 100).round()}% of '
                    '${_rs(stats.monthlyBudget).replaceAll('.00', '')} budget',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC9D4BC),
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  over
                      ? '${_rs(-stats.remaining)} over'
                      : '${_rs(stats.remaining)} left',
                  style: TextStyle(
                    color: over ? const Color(0xFFFF8A8D) : emerald,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.items});

  final List<(IconData, String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      for (var i = 0; i < items.length; i++)
        InkWell(
          onTap: items[i].$3,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: i == 0 ? emerald : context.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    items[i].$1,
                    color: i == 0 ? navy : context.ink,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final peak = stats.week.fold<double>(0, (a, b) => a > b ? a : b);
    final values = [
      for (final v in stats.week)
        peak == 0 ? 0.04 : (v / peak).clamp(0.04, 1.0),
    ];
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  _rs(stats.weekTotal).replaceAll('.00', ''),
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'this week',
                  style: TextStyle(color: context.faint, fontSize: 12),
                ),
                const Spacer(),
                _ChangeBadge(
                  percent: DashboardStats.change(
                    stats.weekTotal,
                    stats.previousWeekTotal,
                  ),
                  background: context.subtle,
                  upColor: const Color(0xFF9A1519),
                  downColor: const Color(0xFF2B5D12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 112,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(values.length, (index) {
                  final selected = index == stats.todayIndex;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 23,
                        height: 82 * values[index],
                        decoration: BoxDecoration(
                          color: selected ? navy : emerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: selected ? context.ink : context.faint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final top = stats.topCategories;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: top.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'No spending recorded this month',
                    style: TextStyle(color: context.faint, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    CategoryProgress(
                      icon: top[i].$3.icon,
                      color: top[i].$3.background,
                      iconColor: top[i].$3.iconColor,
                      title: top[i].$1,
                      amount: _rs(top[i].$2).replaceAll('.00', ''),
                      percent: stats.monthTotal == 0
                          ? 0
                          : top[i].$2 / stats.monthTotal,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class CategoryProgress extends StatelessWidget {
  const CategoryProgress({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.percent,
  });
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: navy, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: emerald),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    amount,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 5,
                  backgroundColor: context.subtle,
                  valueColor: AlwaysStoppedAnimation(context.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Spacer(),
      TextButton(
        onPressed: onTap,
        child: Text(
          action,
          style: TextStyle(
            color: context.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onTap});
  final ExpenseItem expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: navy,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(expense.icon, color: emerald, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${expense.date} · ${expense.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${expense.amount}',
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ExpenseActionsMenu(expense: expense),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
