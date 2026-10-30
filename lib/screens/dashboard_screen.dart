import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'expense_history_screen.dart';
import 'finora_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.onAddExpense,
  });

  final List<ExpenseItem> expenses;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _HomeHeader(
                onNotifications: () =>
                    showMessage(context, 'You are all caught up'),
              ),
              const SizedBox(height: 22),
              const MonthSelector(),
              const SizedBox(height: 14),
              const BalanceCard(),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Spending overview',
                action: 'This week',
                onTap: () => showMessage(context, 'Weekly view selected'),
              ),
              const SizedBox(height: 12),
              const SpendingChart(),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Where your money goes',
                action: 'See all',
                onTap: () => showMessage(context, 'Reports coming soon'),
              ),
              const SizedBox(height: 12),
              const CategoryBreakdown(),
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
              ...expenses
                  .take(3)
                  .map(
                    (expense) => ExpenseTile(
                      expense: expense,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpenseDetailsScreen(expense: expense),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => showMessage(context, 'Settings coming soon'),
          child: const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFDCEBFF),
            child: Text(
              'AS',
              style: TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'Alex Silva',
                style: TextStyle(
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotifications,
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          icon: const Badge(
            smallSize: 7,
            backgroundColor: coral,
            child: Icon(Icons.notifications_none_rounded, color: navy),
          ),
        ),
      ],
    );
  }
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('October 2026', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 20),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: navy,
          ),
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2214213D),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TOTAL SPENT',
                style: TextStyle(
                  color: Color(0xFFB4C0D4),
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2234D399),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      color: Color(0xFF6EE7B7),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '8.4%',
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rs. 45,000.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Monthly budget',
                style: TextStyle(color: Color(0xFFB4C0D4), fontSize: 12),
              ),
              const Spacer(),
              const Text(
                'Rs. 75,000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: .6,
              minHeight: 8,
              backgroundColor: Color(0x335B6B87),
              valueColor: AlwaysStoppedAnimation(emerald),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rs. 30,000.00 remaining',
            style: TextStyle(
              color: Color(0xFF9FE8C8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    const values = [0.35, 0.62, 0.45, 0.82, 0.54, 0.72, 0.28];
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Rs. 12,480',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'this week',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFBF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+12.5%',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  final selected = index == 4;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 23,
                        height: 82 * values[index],
                        decoration: BoxDecoration(
                          color: selected ? navy : const Color(0xFFB9EBD8),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: selected ? navy : const Color(0xFF94A3B8),
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
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            CategoryProgress(
              icon: Icons.restaurant_rounded,
              color: Color(0xFFFFE7D6),
              iconColor: Color(0xFFF97316),
              title: 'Food & Dining',
              amount: 'Rs. 18,240',
              percent: 0.72,
            ),
            SizedBox(height: 14),
            CategoryProgress(
              icon: Icons.directions_car_filled_rounded,
              color: Color(0xFFE8F3FF),
              iconColor: Color(0xFF3B82F6),
              title: 'Transport',
              amount: 'Rs. 9,850',
              percent: 0.48,
            ),
            SizedBox(height: 14),
            CategoryProgress(
              icon: Icons.shopping_bag_rounded,
              color: Color(0xFFF3E8FF),
              iconColor: Color(0xFFA855F7),
              title: 'Shopping',
              amount: 'Rs. 7,460',
              percent: 0.34,
            ),
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
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: iconColor),
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
                    style: const TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: navy,
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
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(iconColor),
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
          style: const TextStyle(
            color: emerald,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: expense.background,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(expense.icon, color: expense.iconColor, size: 20),
      ),
      title: Text(
        expense.title,
        style: const TextStyle(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${expense.category}  •  ${expense.date}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ),
      trailing: Text(
        '- ${expense.amount}',
        style: const TextStyle(
          color: navy,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
