import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required String title,
    required TransactionType type,
    required int amountCents,
    required DateTime occurredAt,
    required TransactionStatus status,
    required String reference,
    String? accountName,
    String? token,
  }) = _TransactionModel;

  const TransactionModel._();

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Transaction toEntity() => Transaction(
    id: id,
    title: title,
    type: type,
    amount: Money(amountCents),
    occurredAt: occurredAt,
    status: status,
    reference: reference,
    accountName: accountName,
    token: token,
  );
}
