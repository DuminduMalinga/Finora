import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'expense_history_screen.dart';
import 'app_colors.dart';

const _months = [
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
const _colors = [
  Color(0xFF6366F1),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF0EA5E9),
  Color(0xFFA855F7),
  Color(0xFFF97316),
];

String _money(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  return 'LKR ${parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}.${parts.last}';
}

/// Aggregates legacy display dates relative to today, never the selected month.
class MonthlyReportData {
  MonthlyReportData(List<ExpenseItem> expenses, this.month, {DateTime? today}) {
    final reference = today ?? DateTime.now();
    final previous = DateTime(month.year, month.month - 1);
    weeks = List.filled(
      (DateTime(month.year, month.month + 1, 0).day / 7).ceil(),
      0,
    );
    for (final expense in expenses) {
      final date = parseDate(expense.date, reference);
      final amount = double.tryParse(
        expense.amount
            .replaceFirst(RegExp(r'^(LKR|Rs\.)\s*'), '')
            .replaceAll(',', '')
            .trim(),
      );
      if (date == null || amount == null || !amount.isFinite || amount <= 0) {
        continue;
      }
      if (date.year == previous.year && date.month == previous.month) {
        previousTotal += amount;
      }
      if (date.year != month.year || date.month != month.month) continue;
      total += amount;
      count++;
      categories.update(
        expense.category,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      weeks[(date.day - 1) ~/ 7] += amount;
    }
  }

  final DateTime month;
  double total = 0;
  double previousTotal = 0;
  int count = 0;
  final Map<String, double> categories = {};
  late final List<double> weeks;
  List<MapEntry<String, double>> get ranked =>
      categories.entries.toList()..sort((a, b) {
        final result = b.value.compareTo(a.value);
        return result == 0 ? a.key.compareTo(b.key) : result;
      });

  static DateTime? parseDate(String value, DateTime today) {
    final day = DateUtils.dateOnly(today);
    if (value.startsWith('Today')) return day;
    if (value.startsWith('Yesterday')) {
      return day.subtract(const Duration(days: 1));
    }
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final match = RegExp(r'^(\w{3}) (\d{1,2})(?:, (\d{4}))?').firstMatch(value);
    if (match == null) return null;
    final month = _months.indexWhere((name) => name.startsWith(match[1]!));
    if (month < 0) return null;
    final date = DateTime(
      int.tryParse(match[3] ?? '') ?? today.year,
      month + 1,
      int.parse(match[2]!),
    );
    return date.month == month + 1 ? date : null;
  }
}

class MonthlyReportsScreen extends StatefulWidget {
  const MonthlyReportsScreen({
    super.key,
    required this.expenses,
    this.initialMonth,
  });
  final List<ExpenseItem> expenses;
  final DateTime? initialMonth;

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _month = DateTime(initial.year, initial.month);
  }

  void _move(int offset) =>
      setState(() => _month = DateTime(_month.year, _month.month + offset));

  Future<void> _chooseMonth() async {
    var year = _month.year;
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Choose a month'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Previous year',
                      onPressed: () => update(() => year--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Next year',
                      onPressed: () => update(() => year++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    12,
                    (index) => SizedBox(
                      width: 76,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(76, 48),
                          backgroundColor:
                              year == _month.year && index + 1 == _month.month
                              ? context.tint
                              : null,
                        ),
                        onPressed: () =>
                            Navigator.pop(context, DateTime(year, index + 1)),
                        child: Text(_months[index].substring(0, 3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _month = selected);
  }

  @override
  Widget build(BuildContext context) {
    final report = MonthlyReportData(widget.expenses, _month);
    final ranked = report.ranked;
    final previousName =
        _months[DateTime(_month.year, _month.month - 1).month - 1];
    final difference = report.total - report.previousTotal;
    final comparison = report.previousTotal == 0
        ? 'No spending recorded in $previousName to compare.'
        : difference == 0
        ? 'Same spending as $previousName'
        : '${(difference.abs() / report.previousTotal * 100).toStringAsFixed(1)}% ${difference > 0 ? 'more' : 'less'} than $previousName';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: context.page,
        foregroundColor: context.ink,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ExpenseHistoryScreen(expenses: widget.expenses),
              ),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('View History'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Text(
            'Your Finora spending snapshot',
            style: TextStyle(color: context.muted),
          ),
          const SizedBox(height: 18),
          _Panel(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _chooseMonth,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_months[_month.month - 1]} ${_month.year}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: context.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SPENDING',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _money(report.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.count} ${report.count == 1 ? 'transaction' : 'transactions'} • ${_months[_month.month - 1]}',
                  style: const TextStyle(color: Color(0xFFCBD5E1)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFF334155)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      report.previousTotal == 0 || difference == 0
                          ? Icons.remove_rounded
                          : difference > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: report.previousTotal > 0 && difference > 0
                          ? const Color(0xFFFDA4AF)
                          : const Color(0xFF6EE7B7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comparison,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$previousName total: ${_money(report.previousTotal)}',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (report.count == 0)
            _Panel(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: context.tint,
                      child: Icon(
                        Icons.insights_rounded,
                        color: context.ink,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'A fresh page for your spending',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded for ${_months[_month.month - 1]} ${_month.year}. Add an expense or choose another month to see your report.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _move(-1),
                      child: const Text('View previous month'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Heading('Spending by category'),
                  const SizedBox(height: 20),
                  Center(
                    child: Semantics(
                      label:
                          'Category spending donut chart. See the category breakdown below for amounts and percentages.',
                      image: true,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            ranked.map((e) => e.value / report.total).toList(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${ranked.length}',
                                  style: TextStyle(
                                    color: context.ink,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'categories',
                                  style: TextStyle(color: context.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: List.generate(
                      ranked.length,
                      (i) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Dot(_colors[i % _colors.length]),
                          const SizedBox(width: 6),
                          Text(ranked[i].key),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Heading('Weekly spending'),
                  const SizedBox(height: 4),
                  Text(
                    'LKR totals • grouped by day of month',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _WeeklyChart(weeks: report.weeks, month: _month),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Heading('Category breakdown'),
                  const SizedBox(height: 4),
                  Text(
                    'Ranked by spending • share of monthly total',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                  for (var i = 0; i < ranked.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  color: context.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ranked[i].key,
                                  style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _money(ranked[i].value),
                                    style: TextStyle(
                                      color: context.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${(ranked[i].value / report.total * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: context.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ranked[i].value / report.total,
                              minHeight: 6,
                              color: _colors[i % _colors.length],
                              backgroundColor: context.page,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.ink,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.shares);
  final List<double> shares;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);
    var start = -math.pi / 2;
    for (var i = 0; i < shares.length; i++) {
      final sweep = shares[i] * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = _colors[i % _colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weeks, required this.month});
  final List<double> weeks;
  final DateTime month;
  @override
  Widget build(BuildContext context) {
    final maxValue = weeks.reduce(math.max);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(weeks.length, (i) {
            final range = '${i * 7 + 1}–${math.min((i + 1) * 7, lastDay)}';
            return Expanded(
              child: Semantics(
                label: 'Week ${i + 1}, days $range: ${_money(weeks[i])}',
                child: Tooltip(
                  message: 'Days $range: ${_money(weeks[i])}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              weeks[i].toStringAsFixed(0),
                              style: TextStyle(
                                color: context.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: 0.65,
                              child: Container(
                                height: maxValue == 0
                                    ? 2
                                    : math.max(2, weeks[i] / maxValue * 110),
                                decoration: BoxDecoration(
                                  color: weeks[i] == maxValue
                                      ? context.primary
                                      : const Color(0xFFA5B4FC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'W${i + 1}',
                          style: TextStyle(
                            color: context.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          range,
                          style: TextStyle(color: context.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Week ranges show days of the selected month.\nExact amounts available on long press.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted, fontSize: 11),
        ),
      ],
    );
  }
}
