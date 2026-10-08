import '../../domain/entities/expense.dart';

/// Data model that bridges the domain [Expense] entity and the SQLite database.
///
/// Handles serialization to/from Map<String, dynamic> for database operations.
class ExpenseModel {
  final int? id;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final String category;
  final String date;       // Stored as ISO-8601 string
  final String? notes;
  final String? imagePath;
  final String? rawOcrText;
  final String createdAt;  // ISO-8601

  const ExpenseModel({
    this.id,
    required this.merchantName,
    required this.totalAmount,
    required this.currency,
    required this.category,
    required this.date,
    this.notes,
    this.imagePath,
    this.rawOcrText,
    required this.createdAt,
  });

  /// Create an ExpenseModel from a database row.
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      merchantName: (map['merchant_name'] as String?) ?? 'Unknown',
      totalAmount: (map['total_amount'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'VND',
      category: (map['category'] as String?) ?? 'Food',
      date: map['date'] as String,
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to a map for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'category': category,
      'date': date,
      'notes': notes,
      'image_path': imagePath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt,
    };
  }

  /// Convert from domain entity to data model.
  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      merchantName: entity.merchantName,
      totalAmount: entity.totalAmount,
      currency: entity.currency,
      category: entity.category,
      date: entity.date.toIso8601String(),
      notes: entity.notes,
      imagePath: entity.imagePath,
      rawOcrText: entity.rawOcrText,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  /// Convert this data model to a domain entity.
  Expense toEntity() {
    return Expense(
      id: id,
      merchantName: merchantName,
      totalAmount: totalAmount,
      currency: currency,
      category: category,
      date: DateTime.parse(date),
      notes: notes,
      imagePath: imagePath,
      rawOcrText: rawOcrText,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
