import 'package:flutter/material.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';

IconData transactionIcon(TransactionType type) => switch (type) {
  TransactionType.transfer => Icons.send_rounded,
  TransactionType.payment => Icons.credit_card_rounded,
  TransactionType.deposit => Icons.south_west_rounded,
  TransactionType.airtime => Icons.phone_android_rounded,
  TransactionType.data => Icons.wifi_rounded,
  TransactionType.electricity => Icons.bolt_rounded,
};
