/// Parsed receipt data extracted from OCR text via regex heuristics.
class ParsedReceipt {
  final double? totalAmount;
  final String? currency;
  final DateTime? date;
  final String? merchantName;
  final List<String> lineItems;
  final double confidence; // 0.0 to 1.0

  const ParsedReceipt({
    this.totalAmount,
    this.currency,
    this.date,
    this.merchantName,
    this.lineItems = const [],
    this.confidence = 0.0,
  });

  /// Returns true if at least the total amount was successfully parsed.
  bool get isValid => totalAmount != null && totalAmount! > 0;

  @override
  String toString() =>
      'ParsedReceipt(merchant: $merchantName, total: $totalAmount $currency, '
      'date: $date, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Custom heuristic regex engine for parsing Vietnamese receipts.
///
/// Handles common receipt formats:
/// - Total amounts: "150,000 VND", "150.000 đ", "TỔNG: 150000"
/// - Dates: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
/// - Merchant names: typically the first non-empty line of the receipt
///
/// The parser uses a multi-strategy approach:
/// 1. Try multiple regex patterns for each field
/// 2. Score each match by position and context
/// 3. Return the highest-confidence result
class ReceiptParser {
  // ─── Amount Patterns ───
  // Matches amounts like: 150,000 VND | 150.000đ | 150000 đ
  // Vietnamese receipts commonly use dot as thousand separator
  static final List<RegExp> _amountPatterns = [
    // Pattern 1: Explicit total keywords followed by amount
    //   Matches: "TỔNG CỘNG: 150.000 đ", "Total: 150,000 VND"
    RegExp(
      r'(?:t[oô][\s]?ng(?:\s*c[oộ]ng)?|total|thanh\s*to[aá]n|th[àa]nh\s*ti[eề]n)'
      r'[:\s]*'
      r'([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)'
      r'\s*'
      r'(vn[dđ]|đ[ồô]ng|đ|₫)?',
      caseSensitive: false,
    ),

    // Pattern 2: Amount followed by currency symbol
    //   Matches: "150.000 VND", "150,000đ"
    RegExp(
      r'([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)'
      r'\s*'
      r'(vn[dđ]|đ[ồô]ng|đ|₫)',
      caseSensitive: false,
    ),

    // Pattern 3: Large standalone number (likely VND, no decimals)
    //   Matches: "150000" (>=1000, likely a price)
    RegExp(
      r'(?:^|\s)([\d]{4,}(?:[.,]\d{3})*)(?:\s|$)',
      caseSensitive: false,
    ),
  ];

  // ─── Date Patterns ───
  static final List<RegExp> _datePatterns = [
    // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})'),
    // YYYY/MM/DD or YYYY-MM-DD
    RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})'),
  ];

  // ─── Merchant Heuristic Keywords (lines to skip) ───
  static final RegExp _skipLinePattern = RegExp(
    r'^(\d|total|t[oô]ng|thanh|tax|vat|change|cash|visa|master|card|'
    r'khuy[eế]n|gi[aả]m|discount|subtotal|qty|sl|đvt|stt|---)',
    caseSensitive: false,
  );

  /// Parse raw OCR text into structured receipt data.
  ///
  /// The parser attempts to extract:
  /// - [totalAmount]: The total/grand total from the receipt
  /// - [currency]: Detected currency (defaults to VND)
  /// - [date]: Transaction date
  /// - [merchantName]: Store/merchant name (typically first line)
  /// - [lineItems]: Individual item lines detected
  ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedReceipt(confidence: 0.0);
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Extract each field independently
    final amountResult = _extractAmount(rawText);
    final dateResult = _extractDate(rawText);
    final merchantResult = _extractMerchant(lines);
    final lineItems = _extractLineItems(lines);

    // Calculate confidence score based on successfully parsed fields
    double confidence = 0.0;
    if (amountResult != null) confidence += 0.4;
    if (dateResult != null) confidence += 0.3;
    if (merchantResult != null) confidence += 0.2;
    if (lineItems.isNotEmpty) confidence += 0.1;

    return ParsedReceipt(
      totalAmount: amountResult?.$1,
      currency: amountResult?.$2 ?? 'VND',
      date: dateResult,
      merchantName: merchantResult,
      lineItems: lineItems,
      confidence: confidence,
    );
  }

  /// Extract the total amount and currency from receipt text.
  ///
  /// Strategy:
  /// 1. Try patterns with explicit "total" keywords first (highest priority)
  /// 2. Fall back to amounts with currency symbols
  /// 3. Last resort: find the largest standalone number
  (double, String)? _extractAmount(String text) {
    // Try each pattern in priority order
    for (int i = 0; i < _amountPatterns.length; i++) {
      final matches = _amountPatterns[i].allMatches(text);

      if (matches.isNotEmpty) {
        // For the "total keyword" pattern, take the LAST match
        // (receipts typically have the grand total at the bottom)
        final match = (i == 0) ? matches.last : matches.first;

        final rawAmount = match.group(1);
        if (rawAmount == null) continue;

        final amount = _parseVietnameseAmount(rawAmount);
        if (amount == null || amount <= 0) continue;

        // Detect currency from captured group or default to VND
        String currency = 'VND';
        if (match.groupCount >= 2 && match.group(2) != null) {
          final currSymbol = match.group(2)!.toLowerCase();
          if (currSymbol.contains('vn') || currSymbol.contains('đ') || currSymbol.contains('₫')) {
            currency = 'VND';
          }
        }

        return (amount, currency);
      }
    }
    return null;
  }

  /// Parse a Vietnamese-format number string to double.
  ///
  /// Vietnamese receipts use:
  /// - Dot (.) as thousand separator: 150.000 = 150,000
  /// - Comma (,) sometimes as thousand separator: 150,000
  /// - No decimal places for VND (always whole numbers)
  double? _parseVietnameseAmount(String raw) {
    try {
      String cleaned = raw.trim();

      // Strategy: Determine if dots/commas are thousand separators or decimals
      // In Vietnamese context, 150.000 means 150,000 (not 150.0)
      // Rule: If the last group after a separator has exactly 3 digits,
      //        treat all separators as thousand separators.

      final hasDot = cleaned.contains('.');
      final hasComma = cleaned.contains(',');

      if (hasDot && !hasComma) {
        // Check if dot is thousand separator (Vietnamese style)
        final parts = cleaned.split('.');
        final lastPart = parts.last;
        if (lastPart.length == 3) {
          // 150.000 → 150000 (thousand separator)
          cleaned = cleaned.replaceAll('.', '');
        } else {
          // 150.50 → 150.50 (decimal point, unlikely for VND)
          // Keep as-is for parsing
        }
      } else if (hasComma && !hasDot) {
        final parts = cleaned.split(',');
        final lastPart = parts.last;
        if (lastPart.length == 3) {
          // 150,000 → 150000 (thousand separator)
          cleaned = cleaned.replaceAll(',', '');
        } else {
          // 150,50 → 150.50 (decimal comma)
          cleaned = cleaned.replaceAll(',', '.');
        }
      } else if (hasDot && hasComma) {
        // Mixed: determine which is which by position
        final dotIndex = cleaned.lastIndexOf('.');
        final commaIndex = cleaned.lastIndexOf(',');

        if (dotIndex > commaIndex) {
          // 1,150.50 → comma is thousand sep, dot is decimal
          cleaned = cleaned.replaceAll(',', '');
        } else {
          // 1.150,50 → dot is thousand sep, comma is decimal
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        }
      }

      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Extract date from receipt text.
  ///
  /// Tries DD/MM/YYYY first (common in Vietnam), then YYYY-MM-DD.
  DateTime? _extractDate(String text) {
    // Pattern 1: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final match1 = _datePatterns[0].firstMatch(text);
    if (match1 != null) {
      final day = int.tryParse(match1.group(1)!);
      final month = int.tryParse(match1.group(2)!);
      final year = int.tryParse(match1.group(3)!);

      if (day != null && month != null && year != null) {
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }
    }

    // Pattern 2: YYYY-MM-DD
    final match2 = _datePatterns[1].firstMatch(text);
    if (match2 != null) {
      final year = int.tryParse(match2.group(1)!);
      final month = int.tryParse(match2.group(2)!);
      final day = int.tryParse(match2.group(3)!);

      if (day != null && month != null && year != null) {
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  /// Validate a date is reasonable (not in the far future or past).
  bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2100) return false;

    try {
      final date = DateTime(year, month, day);
      // Verify the date didn't overflow (e.g., Feb 30 → Mar 2)
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  /// Extract merchant name from receipt lines.
  ///
  /// Heuristic: The merchant name is typically one of the first
  /// non-numeric, non-keyword lines on the receipt.
  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(5)) {
      // Skip lines that look like numbers, dates, or known keywords
      if (_skipLinePattern.hasMatch(line)) continue;

      // Skip very short lines (likely noise) or very long lines (addresses)
      if (line.length < 3 || line.length > 60) continue;

      // Skip lines that are mostly digits
      final digitCount = line.replaceAll(RegExp(r'[^\d]'), '').length;
      if (digitCount > line.length * 0.5) continue;

      return line;
    }
    return null;
  }

  /// Extract individual line items that look like product entries.
  ///
  /// A line item typically contains a name followed by a price.
  List<String> _extractLineItems(List<String> lines) {
    final itemPattern = RegExp(
      r'^(.+?)\s+(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\s*$',
    );

    final items = <String>[];
    for (final line in lines) {
      if (itemPattern.hasMatch(line)) {
        // Don't include total/subtotal lines as items
        if (!RegExp(r'(total|t[oô]ng|thanh|sub)', caseSensitive: false)
            .hasMatch(line)) {
          items.add(line);
        }
      }
    }
    return items;
  }
}
