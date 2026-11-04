import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('mobileNumber', () {
      expect(Validators.mobileNumber(''), isNotNull);
      expect(Validators.mobileNumber('12345'), isNotNull);
      expect(Validators.mobileNumber('082 555 0142'), isNull);
    });

    test('meterNumber', () {
      expect(Validators.meterNumber(''), isNotNull);
      expect(Validators.meterNumber('123'), isNotNull);
      expect(Validators.meterNumber('12345678901'), isNull);
    });

    test('accountNumber', () {
      expect(Validators.accountNumber(''), isNotNull);
      expect(Validators.accountNumber('12'), isNotNull);
      expect(Validators.accountNumber('1450028813'), isNull);
    });

    test('required', () {
      expect(Validators.required('  ', 'a name'), 'Enter a name');
      expect(Validators.required('Sipho', 'a name'), isNull);
    });

    test('email', () {
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b.co.za'), isNull);
    });

    test('amount', () {
      const available = Money(10000);
      expect(Validators.amount('', available: available), isNotNull);
      expect(Validators.amount('0', available: available), isNotNull);
      expect(Validators.amount('100.01', available: available), isNotNull);
      expect(Validators.amount('100', available: available), isNull);
    });
  });

  group('formatters', () {
    final date = DateTime(2026, 3, 4, 9, 5);

    test('dates', () {
      expect(formatDay(date), '4 Mar 2026');
      expect(formatDayTime(date), '4 Mar 2026, 09:05');
      expect(formatMonthYear(date), 'March 2026');
    });

    test('groupToken splits into fours', () {
      expect(groupToken('12345678'), '1234 5678');
    });

    test('formatPoints groups thousands', () {
      expect(formatPoints(12480), '12 480');
    });
  });

  test('AppClock returns the current time', () {
    final before = DateTime.now();
    expect(AppClock().now().isBefore(before), isFalse);
  });
}
