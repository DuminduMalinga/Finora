import 'expense_model.dart';
import 'finora_store.dart';
import 'monthly_reports_screen.dart';

/// How serious a notification is.
enum AlertLevel { over, warning }

class AppNotification {
  const AppNotification({
    required this.key,
    required this.level,
    required this.title,
    required this.message,
  });

  /// Stable identity of this alert within a month, used so each alert is
  /// announced only once (for example `budget:over` or `cat:food:warning`).
  final String key;
  final AlertLevel level;
  final String title;
  final String message;
}

String _lkr(double amount) => 'LKR ${formatAmount(amount, decimals: 0)}';

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
          key: 'budget:over',
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
          key: 'budget:warning',
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
          key: 'cat:${entry.key.toLowerCase()}:over',
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
          key: 'cat:${entry.key.toLowerCase()}:warning',
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
