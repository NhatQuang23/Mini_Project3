/// Pure domain entity representing a single expense record.
/// This class has no dependency on any database or framework.
class Expense {
  final int? id;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final String category;
  final DateTime date;
  final String? notes;
  final String? imagePath;   // Path to receipt thumbnail
  final String? rawOcrText;  // Raw text extracted by OCR
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.merchantName,
    required this.totalAmount,
    this.currency = 'VND',
    required this.category,
    required this.date,
    this.notes,
    this.imagePath,
    this.rawOcrText,
    required this.createdAt,
  });

  /// Create a copy of this expense with optional field overrides.
  Expense copyWith({
    int? id,
    String? merchantName,
    double? totalAmount,
    String? currency,
    String? category,
    DateTime? date,
    String? notes,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, merchant: $merchantName, amount: $totalAmount $currency, '
      'category: $category, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          merchantName == other.merchantName &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode => Object.hash(id, merchantName, totalAmount);
}
