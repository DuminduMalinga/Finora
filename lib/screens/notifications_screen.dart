import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'budget_alerts.dart';
import 'finora_store.dart';
import 'finora_theme.dart';

export 'budget_alerts.dart';

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
