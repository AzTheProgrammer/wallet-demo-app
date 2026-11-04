import 'package:equatable/equatable.dart';
import 'package:wallet_app/core/domain/money.dart';

enum TransactionType {
  transfer('Transfer'),
  payment('Card payment'),
  deposit('Money in'),
  airtime('Airtime'),
  data('Data'),
  electricity('Electricity');

  const TransactionType(this.label);

  final String label;
}

enum TransactionStatus { completed, pending, failed }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.status,
    required this.reference,
    this.accountName,
    this.token,
  });

  final String id;
  final String title;
  final TransactionType type;
  final Money amount;
  final DateTime occurredAt;
  final TransactionStatus status;
  final String reference;
  final String? accountName;
  final String? token;

  bool get isIncoming => amount.isPositive;

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    amount,
    occurredAt,
    status,
    reference,
    accountName,
    token,
  ];
}
