import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/money.dart';

void main() {
  group('format', () {
    test('groups thousands with non-breaking spaces', () {
      expect(const Money(123456789).format(), 'R 1 234 567.89');
    });

    test('pads cents', () {
      expect(const Money(105).format(), 'R 1.05');
    });

    test('shows negatives with a leading minus', () {
      expect(const Money(-2500).format(), '-R 25.00');
    });

    test('toString matches format', () {
      expect(const Money(100).toString(), const Money(100).format());
    });
  });

  group('tryParse', () {
    test('reads whole rands', () {
      expect(Money.tryParse('150'), const Money(15000));
    });

    test('reads a dot or comma as the decimal separator', () {
      expect(Money.tryParse('12.5'), const Money(1250));
      expect(Money.tryParse('12,50'), const Money(1250));
    });

    test('ignores spaces and the currency symbol', () {
      expect(Money.tryParse('R 1 000'), const Money(100000));
    });

    test('rejects anything else', () {
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse('1.234'), isNull);
      expect(Money.tryParse(''), isNull);
    });
  });

  test('arithmetic and comparison', () {
    const five = Money(500);
    const two = Money(200);
    expect(five + two, const Money(700));
    expect(five - two, const Money(300));
    expect(five > two, isTrue);
    expect(two < five, isTrue);
    expect(five.compareTo(two), 1);
    expect(Money.zero.isZero, isTrue);
    expect(five.isPositive, isTrue);
  });
}
