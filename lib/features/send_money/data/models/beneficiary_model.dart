import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';

part 'beneficiary_model.freezed.dart';
part 'beneficiary_model.g.dart';

@freezed
abstract class BeneficiaryModel with _$BeneficiaryModel {
  const factory BeneficiaryModel({
    required String id,
    required String name,
    required String bank,
    required String accountNumber,
  }) = _BeneficiaryModel;

  const BeneficiaryModel._();

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryModelFromJson(json);

  Beneficiary toEntity() =>
      Beneficiary(id: id, name: name, bank: bank, accountNumber: accountNumber);
}

@freezed
abstract class SendReceiptModel with _$SendReceiptModel {
  const factory SendReceiptModel({
    required String transactionId,
    required String reference,
    required DateTime sentAt,
  }) = _SendReceiptModel;

  const SendReceiptModel._();

  factory SendReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$SendReceiptModelFromJson(json);

  SendMoneyReceipt toEntity() => SendMoneyReceipt(
    transactionId: transactionId,
    reference: reference,
    sentAt: sentAt,
  );
}
