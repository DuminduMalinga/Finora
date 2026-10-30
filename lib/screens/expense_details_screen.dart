import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'finora_theme.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    this.onUpdated,
    this.onDeleted,
  });

  final ExpenseItem expense;
  final ValueChanged<ExpenseItem>? onUpdated;
  final VoidCallback? onDeleted;

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  late ExpenseItem _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _editExpense() async {
    final updated = await Navigator.of(context).push<ExpenseItem>(
      MaterialPageRoute(builder: (_) => _EditExpenseScreen(expense: _expense)),
    );
    if (updated == null || !mounted) return;
    setState(() => _expense = updated);
    widget.onUpdated?.call(updated);
    showMessage(context, 'Expense updated successfully');
  }

  Future<void> _deleteExpense() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This expense will be permanently removed from your history.',
        ),
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
    if (shouldDelete != true || !mounted) return;
    widget.onDeleted?.call();
    Navigator.pop(context);
    showMessage(context, 'Expense deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: canvas,
        foregroundColor: navy,
        actions: [
          IconButton(
            tooltip: 'Edit expense',
            onPressed: _editExpense,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: _deleteExpense,
            icon: const Icon(Icons.delete_outline_rounded, color: coral),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _expense.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expense.icon,
                      color: _expense.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _expense.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LKR ${_amount(_expense.amount)}',
                    style: const TextStyle(
                      color: coral,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _expense.date,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Category',
                  value: _expense.category,
                  icon: Icons.grid_view_rounded,
                ),
                const Divider(height: 1, indent: 64),
                _DetailRow(
                  label: 'Payment method',
                  value: _expense.paymentMethod,
                  icon: Icons.credit_card_rounded,
                ),
                const Divider(height: 1, indent: 64),
                _DetailRow(
                  label: 'Notes',
                  value: _expense.notes.isEmpty
                      ? 'No notes added'
                      : _expense.notes,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _editExpense,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Expense'),
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: navy),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _deleteExpense,
            icon: const Icon(Icons.delete_outline_rounded, color: coral),
            label: const Text(
              'Delete Expense',
              style: TextStyle(color: coral, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExpenseScreen extends StatefulWidget {
  const _EditExpenseScreen({required this.expense});

  final ExpenseItem expense;

  @override
  State<_EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<_EditExpenseScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _paymentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _amount(widget.expense.amount),
    );
    _titleController = TextEditingController(text: widget.expense.title);
    _notesController = TextEditingController(text: widget.expense.notes);
    _paymentController = TextEditingController(
      text: widget.expense.paymentMethod,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExpenseItem(
        title: _titleController.text.trim(),
        category: widget.expense.category,
        amount: 'LKR ${_amountController.text.trim()}',
        date: widget.expense.date,
        icon: widget.expense.icon,
        iconColor: widget.expense.iconColor,
        background: widget.expense.background,
        paymentMethod: _paymentController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        backgroundColor: canvas,
        foregroundColor: navy,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _EditField(
              label: 'Amount',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'LKR ',
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _EditField(
              label: 'Expense title',
              controller: _titleController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 18),
            _EditField(label: 'Payment method', controller: _paymentController),
            const SizedBox(height: 18),
            _EditField(
              label: 'Notes',
              controller: _notesController,
              maxLines: 3,
              hintText: 'Add a note...',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixText,
    this.maxLines = 1,
    this.hintText,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int maxLines;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefixText,
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: navy, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _amount(String value) {
  return value.replaceFirst(RegExp(r'^(LKR|Rs\.)\s*'), '');
}
