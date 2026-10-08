import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import '../../services/receipt_parser.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/stats_viewmodel.dart';
import '../widgets/category_chip.dart';

/// Review screen where users can edit OCR-parsed receipt data before saving.
///
/// Receives parsed receipt data and image path from the camera screen.
/// All fields are pre-filled but fully editable.
class ReviewScreen extends StatefulWidget {
  final ParsedReceipt parsedReceipt;
  final String? imagePath;
  final String? rawOcrText;

  const ReviewScreen({
    super.key,
    required this.parsedReceipt,
    this.imagePath,
    this.rawOcrText,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    final receipt = widget.parsedReceipt;

    _merchantController = TextEditingController(
      text: receipt.merchantName ?? '',
    );
    _amountController = TextEditingController(
      text: receipt.totalAmount?.toStringAsFixed(0) ?? '',
    );
    _selectedDate = receipt.date ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormatter.toDisplay(_selectedDate!),
    );
    _notesController = TextEditingController();
    _selectedCategory = 'Food'; // Default category
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          TextButton.icon(
            onPressed: _saveExpense,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Confidence Badge ───
              _ConfidenceBadge(
                confidence: widget.parsedReceipt.confidence,
              ),
              const SizedBox(height: 16),

              // ─── Receipt Image Preview ───
              if (widget.imagePath != null) ...[                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Merchant Name ───
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant Name',
                  prefixIcon: Icon(Icons.store),
                  hintText: 'e.g. Bách Hóa Xanh',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the merchant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Total Amount ───
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (VND)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'e.g. 150000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the amount';
                  }
                  final amount = double.tryParse(
                    value.replaceAll(RegExp(r'[^\d.]'), ''),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Date ───
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'DD/MM/YYYY',
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),

              // ─── Category Selector ───
              Text(
                'Category',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categories.map((category) {
                  return CategoryChip(
                    category: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() => _selectedCategory = category);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ─── Notes ───
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Add any notes...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ─── Raw OCR Text (collapsible) ───
              if (widget.rawOcrText != null && widget.rawOcrText!.isNotEmpty)
                ExpansionTile(
                  title: const Text('Raw OCR Text'),
                  leading: const Icon(Icons.text_snippet),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        widget.rawOcrText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // ─── Save Button ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saveExpense,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormatter.toDisplay(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d.]'), ''),
    );

    final expense = Expense(
      merchantName: _merchantController.text.trim(),
      totalAmount: amount,
      currency: AppConstants.defaultCurrency,
      category: _selectedCategory,
      date: _selectedDate ?? DateTime.now(),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      imagePath: widget.imagePath,
      rawOcrText: widget.rawOcrText,
      createdAt: DateTime.now(),
    );

    // Save through the HomeViewModel
    final homeVm = context.read<HomeViewModel>();
    await homeVm.addExpense(expense);

    // Refresh stats
    if (mounted) {
      context.read<StatsViewModel>().loadStats();
    }

    // Navigate back to home
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Badge showing the OCR parsing confidence level.
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).round();
    final Color color;
    final String label;

    if (confidence >= 0.7) {
      color = Colors.green;
      label = 'High confidence';
    } else if (confidence >= 0.4) {
      color = Colors.orange;
      label = 'Medium confidence';
    } else {
      color = Colors.red;
      label = 'Low confidence';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_high, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label ($percentage%)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
