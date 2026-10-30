import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'expense_details_screen.dart';
import 'expense_model.dart';
import 'finora_store.dart';
import 'finora_theme.dart';

/// Opens the edit form for [expense] and saves the changes.
Future<void> editExpense(BuildContext context, ExpenseItem expense) async {
  final store = FinoraScope.maybeOf(context);
  if (store == null) return;
  final updated = await Navigator.of(context).push<ExpenseItem>(
    MaterialPageRoute(
      builder: (_) =>
          EditExpenseScreen(expense: expense, categories: store.categories),
    ),
  );
  if (updated == null || !context.mounted) return;
  store.replaceExpense(expense, updated);
  showMessage(context, 'Expense updated successfully');
}

/// Asks for confirmation, deletes [expense], and offers an Undo.
Future<void> deleteExpense(BuildContext context, ExpenseItem expense) async {
  final store = FinoraScope.maybeOf(context);
  if (store == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete expense?'),
      content: Text('“${expense.title}” will be removed from your history.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: coral),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final index = store.expenses.indexOf(expense);
  store.removeExpense(expense);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text('Expense deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.restoreExpense(expense, index),
        ),
      ),
    );
}

/// The "⋮" button on an expense row: Edit and Delete, always in sight.
class ExpenseActionsMenu extends StatelessWidget {
  const ExpenseActionsMenu({super.key, required this.expense});

  final ExpenseItem expense;

  @override
  Widget build(BuildContext context) {
    if (FinoraScope.maybeOf(context) == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Expense actions',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Icons.more_vert_rounded, color: context.muted, size: 20),
      onSelected: (value) {
        if (value == 'edit') editExpense(context, expense);
        if (value == 'delete') deleteExpense(context, expense);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, color: coral),
            title: Text('Delete', style: TextStyle(color: coral)),
          ),
        ),
      ],
    );
  }
}
