import 'package:equatable/equatable.dart';

class Money extends Equatable implements Comparable<Money> {
  const Money(this.cents);

  static const zero = Money(0);

  final int cents;

  bool get isPositive => cents > 0;

  bool get isZero => cents == 0;

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  bool operator >(Money other) => cents > other.cents;

  bool operator <(Money other) => cents < other.cents;

  static Money? tryParse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\sR]'), '').replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(cleaned)) return null;
    final parts = cleaned.split('.');
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return Money(int.parse(parts[0]) * 100 + int.parse(fraction));
  }

  String format() {
    final absolute = cents.abs();
    final whole = (absolute ~/ 100).toString();
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    final sign = cents < 0 ? '-' : '';
    return '${sign}R $grouped.$fraction';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  List<Object?> get props => [cents];

  @override
  String toString() => format();
}
