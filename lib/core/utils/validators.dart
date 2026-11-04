import 'package:wallet_app/core/domain/money.dart';

abstract final class Validators {
  static String? mobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return 'Enter a mobile number';
    if (!RegExp(r'^0[6-8]\d{8}$').hasMatch(digits)) {
      return 'Enter a 10-digit South African number';
    }
    return null;
  }

  static String? meterNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return 'Enter a meter number';
    if (!RegExp(r'^\d{11}$').hasMatch(digits)) {
      return 'Meter numbers have 11 digits';
    }
    return null;
  }

  static String? accountNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return 'Enter an account number';
    if (!RegExp(r'^\d{9,11}$').hasMatch(digits)) {
      return 'Account numbers have 9 to 11 digits';
    }
    return null;
  }

  static String? required(String value, String label) =>
      value.trim().isEmpty ? 'Enter $label' : null;

  static String? email(String value) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? amount(String value, {required Money available}) {
    final parsed = Money.tryParse(value);
    if (parsed == null || !parsed.isPositive) return 'Enter an amount';
    if (parsed > available) return 'That is more than your available balance';
    return null;
  }
}
