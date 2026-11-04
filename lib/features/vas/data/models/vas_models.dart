import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';

part 'vas_models.freezed.dart';
part 'vas_models.g.dart';

@freezed
abstract class VasProviderModel with _$VasProviderModel {
  const factory VasProviderModel({
    required String id,
    required String name,
    required List<VasKind> kinds,
  }) = _VasProviderModel;

  const VasProviderModel._();

  factory VasProviderModel.fromJson(Map<String, dynamic> json) =>
      _$VasProviderModelFromJson(json);

  VasProvider toEntity() => VasProvider(id: id, name: name);
}

@freezed
abstract class VasOptionModel with _$VasOptionModel {
  const factory VasOptionModel({
    required String id,
    required VasKind kind,
    required String label,
    required int amountCents,
    String? providerId,
    String? detail,
  }) = _VasOptionModel;

  const VasOptionModel._();

  factory VasOptionModel.fromJson(Map<String, dynamic> json) =>
      _$VasOptionModelFromJson(json);

  VasOption toEntity() => VasOption(
    id: id,
    label: label,
    detail: detail,
    amount: Money(amountCents),
  );
}

@freezed
abstract class VasReceiptModel with _$VasReceiptModel {
  const factory VasReceiptModel({
    required String transactionId,
    required String reference,
    required DateTime purchasedAt,
    String? token,
    String? units,
  }) = _VasReceiptModel;

  const VasReceiptModel._();

  factory VasReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$VasReceiptModelFromJson(json);

  VasReceipt toEntity() => VasReceipt(
    transactionId: transactionId,
    reference: reference,
    purchasedAt: purchasedAt,
    token: token,
    units: units,
  );
}
