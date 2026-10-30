import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'categories_screen.dart';
import 'expense_model.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'app_colors.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.onSaved});

  final ValueChanged<ExpenseItem> onSaved;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();

  AppCategory? _category;
  DateTime _date = DateTime.now();
  bool _submitted = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: context.ink),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _validateAmount(String? v) {
    final value = double.tryParse((v ?? '').trim());
    if (value == null) return 'Enter an amount';
    if (value <= 0) return 'Amount must be greater than 0';
    return null;
  }

  String? _validateTitle(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter a title';
    if (t.length < 2) return 'Title is too short';
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    final category = _category;
    if (!valid || category == null) return;

    widget.onSaved(
      ExpenseItem(
        title: _title.text.trim(),
        category: category.name,
        amount: 'LKR ${formatAmount(double.parse(_amount.text.trim()))}',
        date: _formatDate(_date),
        icon: category.icon,
        iconColor: category.color,
        background: category.background,
        notes: _notes.text.trim(),
      ),
    );
    showMessage(context, 'Expense added successfully');
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.faint),
      prefixIcon: icon == null ? null : Icon(icon, color: context.muted),
      filled: true,
      fillColor: context.surface,
      contentPadding: const EdgeInsets.all(16),
      border: border(context.line),
      enabledBorder: border(context.line),
      focusedBorder: border(emerald, 2),
      errorBorder: border(coral),
      focusedErrorBorder: border(coral, 2),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: context.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Add Expense',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _amountField(),
              const SizedBox(height: 24),
              _label('Title'),
              TextFormField(
                controller: _title,
                validator: _validateTitle,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'e.g. Lunch at cafe',
                  icon: Icons.edit_rounded,
                ),
              ),
              const SizedBox(height: 24),
              _label('Category'),
              _categoryGrid(),
              const SizedBox(height: 24),
              _label('Date'),
              _dateField(),
              const SizedBox(height: 24),
              _label('Notes (optional)'),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Add a note...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Expense',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: context.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Amount',
            style: TextStyle(color: context.muted, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 14, right: 8),
                child: Text(
                  'LKR',
                  style: TextStyle(
                    color: emerald,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: TextFormField(
                    controller: _amount,
                    validator: _validateAmount,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,9}\.?\d{0,2}'),
                      ),
                    ],
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: context.faint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: TextStyle(
                        color: coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Lets the user create a category without leaving the form.
  Future<void> _addCategory() async {
    final store = FinoraScope.maybeOf(context);
    if (store == null) return;
    final created = await showDialog<AppCategory>(
      context: context,
      builder: (_) => const CategoryEditorDialog(),
    );
    if (created == null || !mounted) return;
    if (store.categories.any((c) => sameCategory(c.name, created.name))) {
      showMessage(context, '${created.name} already exists');
      return;
    }
    store.addCategory(created);
    setState(() => _category = created);
  }

  Widget _categoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final c
                in FinoraScope.maybeOf(context)?.categories ??
                    defaultCategories)
              _CategoryTile(
                category: c,
                selected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
            if (FinoraScope.maybeOf(context) != null)
              _AddCategoryTile(onTap: _addCategory),
          ],
        ),
        if (_submitted && _category == null)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Select a category',
              style: TextStyle(
                color: coral,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.line),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: context.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(_date),
                style: TextStyle(
                  color: context.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: context.muted),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  const _AddCategoryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: context.ink,
              size: 26,
            ),
            SizedBox(height: 6),
            Text(
              'Add',
              style: TextStyle(
                color: context.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final AppCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? context.tint : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? emerald : context.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: category.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: emerald,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
