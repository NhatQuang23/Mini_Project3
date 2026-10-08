import 'package:flutter/material.dart';

/// Application-wide constants: categories, colors, and configuration.
class AppConstants {
  AppConstants._();

  // ─── Expense Categories ───
  static const List<String> categories = [
    'Food',
    'Study',
    'Travel',
    'Gear',
    'Entertainment',
  ];

  // ─── Category Icons ───
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Study': Icons.school,
    'Travel': Icons.flight,
    'Gear': Icons.devices,
    'Entertainment': Icons.movie,
  };

  // ─── Category Colors ───
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFE53935),        // Red
    'Study': Color(0xFF1E88E5),       // Blue
    'Travel': Color(0xFFFB8C00),      // Orange
    'Gear': Color(0xFF8E24AA),        // Purple
    'Entertainment': Color(0xFF43A047), // Green
  };

  // ─── Database ───
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  static const String expenseTable = 'expenses';

  // ─── Receipt Thumbnail ───
  static const String thumbnailDir = 'receipt_thumbnails';
  static const int thumbnailMaxWidth = 300;
  static const int thumbnailMaxHeight = 400;

  // ─── Currency ───
  static const String defaultCurrency = 'VND';
}
