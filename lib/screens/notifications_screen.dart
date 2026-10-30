import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'expense_model.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';

/// How serious a notification is.
enum AlertLevel { over, warning }

class AppNotification {
  const AppNotification({
    required this.level,
    required this.title,
    required this.message,
  });

  final AlertLevel level;
  final String title;
  final String message;
}

String _lkr(double amount) {
  final whole = amount.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'LKR $whole';
}

/// Budget alerts for the current month, worked out from the user's real
/// spending: the overall budget first, then each category that has a limit.
/// Over-budget alerts come before "almost there" warnings.
List<AppNotification> buildNotifications({
  required List<ExpenseItem> expenses,
  required double monthlyBudget,
  required Map<String, double> limits,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final report = MonthlyReportData(
    expenses,
    DateTime(today.year, today.month),
    today: today,
  );
  final alerts = <AppNotification>[];

  if (monthlyBudget > 0) {
    final used = report.total / monthlyBudget;
    if (report.total > monthlyBudget) {
      alerts.add(
        AppNotification(
          level: AlertLevel.over,
          title: 'Over your monthly budget',
          message:
              'You have spent ${_lkr(report.total)}, which is '
              '${_lkr(report.total - monthlyBudget)} over your '
              '${_lkr(monthlyBudget)} budget.',
        ),
      );
    } else if (used >= 0.8) {
      alerts.add(
        AppNotification(
          level: AlertLevel.warning,
          title: 'Close to your monthly budget',
          message:
              'You have used ${(used * 100).round()}% of your '
              '${_lkr(monthlyBudget)} budget. ${_lkr(monthlyBudget - report.total)} left.',
        ),
      );
    }
  }

  for (final entry in limits.entries) {
    final limit = entry.value;
    if (limit <= 0) continue;
    var spent = 0.0;
    for (final c in report.categories.entries) {
      if (sameCategory(c.key, entry.key)) spent += c.value;
    }
    if (spent > limit) {
      alerts.add(
        AppNotification(
          level: AlertLevel.over,
          title: '${entry.key} is over its limit',
          message:
              '${_lkr(spent)} spent of the ${_lkr(limit)} limit '
              '(${_lkr(spent - limit)} over).',
        ),
      );
    } else if (spent / limit >= 0.8) {
      alerts.add(
        AppNotification(
          level: AlertLevel.warning,
          title: '${entry.key} is almost at its limit',
          message:
              '${(spent / limit * 100).round()}% used: ${_lkr(spent)} of '
              '${_lkr(limit)}. ${_lkr(limit - spent)} left.',
        ),
      );
    }
  }

  alerts.sort((a, b) => a.level.index.compareTo(b.level.index));
  return alerts;
}

/// Lists the current budget alerts. They update as spending changes.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinoraScope.of(context);
    final alerts = buildNotifications(
      expenses: store.expenses,
      monthlyBudget: store.monthlyBudget,
      limits: store.categoryLimits,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: alerts.isEmpty
          ? const _AllCaughtUp()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _AlertCard(alert: alerts[index]),
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final AppNotification alert;

  @override
  Widget build(BuildContext context) {
    final over = alert.level == AlertLevel.over;
    final color = over ? coral : amber;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              over ? Icons.warning_rounded : Icons.error_outline_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: context.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: emerald,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'You’re all caught up',
            style: TextStyle(
              color: context.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We’ll let you know here when you get close to a budget or '
            'category limit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    ),
  );
}
