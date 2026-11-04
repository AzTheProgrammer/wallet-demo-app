import 'package:equatable/equatable.dart';
import 'package:wallet_app/core/domain/money.dart';

enum AccountKind { main, savings }

class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.number,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final Money balance;
  final String number;

  String get maskedNumber => '•••• ${number.substring(number.length - 4)}';

  @override
  List<Object?> get props => [id, name, kind, balance, number];
}
