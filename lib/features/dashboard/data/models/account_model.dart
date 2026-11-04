import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
abstract class AccountModel with _$AccountModel {
  const factory AccountModel({
    required String id,
    required String name,
    required AccountKind kind,
    required int balanceCents,
    required String number,
  }) = _AccountModel;

  const AccountModel._();

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  Account toEntity() => Account(
    id: id,
    name: name,
    kind: kind,
    balance: Money(balanceCents),
    number: number,
  );
}
