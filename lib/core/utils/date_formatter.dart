import 'package:intl/intl.dart';

/// Utility class for date formatting and parsing operations.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayWithTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _dayOfWeek = DateFormat('EEE');

  /// Format a DateTime to display format: "28/09/2026"
  static String toDisplay(DateTime date) => _displayFormat.format(date);

  /// Format a DateTime to ISO-8601 date string: "2026-09-28"
  static String toIso(DateTime date) => _isoFormat.format(date);

  /// Format a DateTime with time: "28/09/2026 14:30"
  static String toDisplayWithTime(DateTime date) =>
      _displayWithTime.format(date);

  /// Format to "September 2026"
  static String toMonthYear(DateTime date) => _monthYear.format(date);

  /// Format to day-of-week abbreviation: "Mon"
  static String toDayOfWeek(DateTime date) => _dayOfWeek.format(date);

  /// Parse an ISO-8601 date string back to DateTime.
  /// Returns null if parsing fails.
  static DateTime? tryParseIso(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Parse a DD/MM/YYYY date string to DateTime.
  /// Returns null if parsing fails.
  static DateTime? tryParseDisplay(String dateStr) {
    try {
      return _displayFormat.parseStrict(dateStr);
    } catch (_) {
      return null;
    }
  }
}
