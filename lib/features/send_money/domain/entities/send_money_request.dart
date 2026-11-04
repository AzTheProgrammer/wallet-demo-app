import 'package:equatable/equatable.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';

class SendMoneyRequest extends Equatable {
  const SendMoneyRequest({
    required this.fromAccountId,
    required this.beneficiary,
    required this.amount,
    required this.reference,
  });

  final String fromAccountId;
  final Beneficiary beneficiary;
  final Money amount;
  final String reference;

  @override
  List<Object?> get props => [fromAccountId, beneficiary, amount, reference];
}

class SendMoneyReceipt extends Equatable {
  const SendMoneyReceipt({
    required this.transactionId,
    required this.reference,
    required this.sentAt,
  });

  final String transactionId;
  final String reference;
  final DateTime sentAt;

  @override
  List<Object?> get props => [transactionId, reference, sentAt];
}

class NewBeneficiary extends Equatable {
  const NewBeneficiary({
    required this.name,
    required this.bank,
    required this.accountNumber,
  });

  final String name;
  final String bank;
  final String accountNumber;

  @override
  List<Object?> get props => [name, bank, accountNumber];
}
