part of 'send_money_bloc.dart';

@freezed
sealed class SendMoneyEvent with _$SendMoneyEvent {
  const factory SendMoneyEvent.started() = SendMoneyStarted;
  const factory SendMoneyEvent.beneficiarySelected(Beneficiary beneficiary) =
      BeneficiarySelected;
  const factory SendMoneyEvent.beneficiaryAdded(NewBeneficiary details) =
      BeneficiaryAdded;
  const factory SendMoneyEvent.accountSelected(Account account) =
      AccountSelected;
  const factory SendMoneyEvent.amountChanged(String amount) = AmountChanged;
  const factory SendMoneyEvent.referenceChanged(String reference) =
      ReferenceChanged;
  const factory SendMoneyEvent.reviewRequested() = ReviewRequested;
  const factory SendMoneyEvent.confirmed() = SendConfirmed;
  const factory SendMoneyEvent.stepBack() = SendStepBack;
}
