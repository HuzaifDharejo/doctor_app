import 'package:intl/intl.dart';

/// Pakistani Rupee currency utilities
class PKRCurrency {
  /// Format amount in Pakistani Rupees
  static String format(double amount, {bool showSymbol = true, int decimals = 0}) {
    final formatter = NumberFormat.currency(
      symbol: showSymbol ? 'Rs. ' : '',
      decimalDigits: decimals,
      locale: 'en_PK',
    );
    return formatter.format(amount);
  }

  /// Format with abbreviated suffix (K, L, Cr for Lakh, Crore)
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return 'Rs. ${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return 'Rs. ${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)} K';
    }
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  /// Parse PKR string back to double
  static double parse(String value) {
    final cleaned = value.replaceAll('Rs.', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }
}

/// Common Pakistani consultation fees
class PKRFees {
  static const double generalConsultation = 2000;
  static const double specialistConsultation = 3000;
  static const double psychiatristConsultation = 5000;
  static const double followUp = 1500;
  static const double emergency = 5000;
  static const double homeVisit = 10000;
}

/// Pakistani payment methods
class PKRPaymentMethods {
  static const List<String> all = [
    'Cash',
    'JazzCash',
    'EasyPaisa',
    'Bank Transfer',
    'HBL',
    'UBL',
    'MCB',
    'Credit Card',
    'Debit Card',
  ];
}
