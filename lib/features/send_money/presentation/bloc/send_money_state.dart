part of 'send_money_bloc.dart';

enum SendMoneyStep { recipient, amount, review, processing, success, failure }

@freezed
abstract class SendMoneyState with _$SendMoneyState {
  const factory SendMoneyState({
    @Default(SendMoneyStep.recipient) SendMoneyStep step,
    @Default(ViewStatus.initial) ViewStatus loadStatus,
    @Default(<Beneficiary>[]) List<Beneficiary> beneficiaries,
    @Default(<Account>[]) List<Account> accounts,
    Beneficiary? beneficiary,
    Account? account,
    @Default('') String amountText,
    @Default('') String reference,
    String? amountError,
    String? referenceError,
    @Default(false) bool isAddingBeneficiary,
    Failure? failure,
    SendMoneyReceipt? receipt,
  }) = _SendMoneyState;

  const SendMoneyState._();

  Money get amount => Money.tryParse(amountText) ?? Money.zero;
}
