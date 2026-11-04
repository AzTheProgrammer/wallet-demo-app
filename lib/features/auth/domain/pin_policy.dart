abstract final class PinPolicy {
  static const length = 5;
  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  static String? validate(String pin) {
    if (!RegExp('^\\d{$length}\$').hasMatch(pin)) {
      return 'Your PIN must have $length digits.';
    }
    if (pin.split('').toSet().length == 1 || _isSequence(pin)) {
      return 'That PIN is too easy to guess. Choose another.';
    }
    return null;
  }

  static bool _isSequence(String pin) {
    final digits = pin.codeUnits;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < digits.length; i++) {
      ascending = ascending && digits[i] == digits[i - 1] + 1;
      descending = descending && digits[i] == digits[i - 1] - 1;
    }
    return ascending || descending;
  }
}
