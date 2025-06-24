import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Collection of useful extensions following clean code principles
///
/// Features:
/// - Meaningful, focused extensions
/// - Null-safe implementations
/// - Documented use cases
/// - Performance-conscious

/// String extensions
extension StringExtensions on String {
  /// Capitalizes first letter of each word
  String get capitalize {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncates string with ellipsis
  String truncate(int maxLength, [String ellipsis = '...']) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Checks if string is a valid email
  bool get isEmail {
    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    return RegExp(pattern).hasMatch(this);
  }

  /// Converts string to currency format
  String toCurrency({String symbol = '', int decimalDigits = 2}) {
    final number = double.tryParse(this);
    if (number == null) return this;
    return number.toCurrency(symbol: symbol, decimalDigits: decimalDigits);
  }
}

/// Number extensions
extension NumberExtensions on num {
  /// Formats number as currency
  String toCurrency({String symbol = '', int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(this);
  }

  /// Formats number with locale-specific separators
  String formatWithCommas({int? decimalDigits}) {
    final pattern = decimalDigits != null
        ? '#,##0.${List.filled(decimalDigits, '0').join()}'
        : null;
    final formatter = pattern != null
        ? NumberFormat(pattern)
        : NumberFormat.decimalPattern();
    return formatter.format(this);
  }

  /// Converts to a formatted file size string
  String toFileSize({bool binary = false}) {
    final bytes = toDouble();
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final divisor = binary ? 1024 : 1000;
    
    var size = bytes;
    var unitIndex = 0;
    
    while (size >= divisor && unitIndex < units.length - 1) {
      size /= divisor;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Formats date according to locale
  String format({String? pattern, String? locale}) {
    return DateFormat(pattern, locale).format(this);
  }

  /// Returns time ago string (e.g. "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  /// Checks if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Safely gets element at index or returns null
  T? elementAtOrNull(int index) {
    try {
      return this[index];
    } catch (_) {
      return null;
    }
  }

  /// Splits list into chunks of specified size
  List<List<T>> chunk(int size) {
    return List.generate(
      (length / size).ceil(),
      (i) => sublist(i * size, min((i + 1) * size, length)),
    );
  }

  /// Returns a new list with distinct elements
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}

/// Context extensions
extension ContextExtensions on BuildContext {
  /// Shortcut for MediaQuery.of
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Shortcut for Theme.of
  ThemeData get theme => Theme.of(this);

  /// Shortcut for Navigator.of
  NavigatorState get navigator => Navigator.of(this);

  /// Shortcut for FocusScope.of
  FocusNode get focusScope => FocusScope.of(this);

  /// Shows a snackbar with consistent styling
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}