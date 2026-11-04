import 'package:equatable/equatable.dart';
import 'package:wallet_app/core/domain/money.dart';

enum VasKind {
  airtime('Airtime', 'Mobile number'),
  data('Data', 'Mobile number'),
  electricity('Electricity', 'Meter number');

  const VasKind(this.label, this.recipientLabel);

  final String label;
  final String recipientLabel;
}

class VasProvider extends Equatable {
  const VasProvider({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class VasOption extends Equatable {
  const VasOption({
    required this.id,
    required this.label,
    required this.amount,
    this.detail,
  });

  final String id;
  final String label;
  final String? detail;
  final Money amount;

  @override
  List<Object?> get props => [id, label, detail, amount];
}

class VasPurchase extends Equatable {
  const VasPurchase({
    required this.kind,
    required this.provider,
    required this.option,
    required this.recipient,
    required this.accountId,
  });

  final VasKind kind;
  final VasProvider provider;
  final VasOption option;
  final String recipient;
  final String accountId;

  @override
  List<Object?> get props => [kind, provider, option, recipient, accountId];
}

class VasReceipt extends Equatable {
  const VasReceipt({
    required this.transactionId,
    required this.reference,
    required this.purchasedAt,
    this.token,
    this.units,
  });

  final String transactionId;
  final String reference;
  final DateTime purchasedAt;
  final String? token;
  final String? units;

  @override
  List<Object?> get props => [
    transactionId,
    reference,
    purchasedAt,
    token,
    units,
  ];
}
