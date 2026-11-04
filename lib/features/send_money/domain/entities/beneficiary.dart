import 'package:equatable/equatable.dart';

class Beneficiary extends Equatable {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.bank,
    required this.accountNumber,
  });

  final String id;
  final String name;
  final String bank;
  final String accountNumber;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  List<Object?> get props => [id, name, bank, accountNumber];
}
