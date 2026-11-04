part of 'vas_bloc.dart';

enum VasStep {
  provider,
  recipient,
  option,
  review,
  processing,
  success,
  failure,
}

@freezed
abstract class VasState with _$VasState {
  const factory VasState({
    @Default(VasKind.airtime) VasKind kind,
    @Default(VasStep.provider) VasStep step,
    @Default(ViewStatus.initial) ViewStatus loadStatus,
    @Default(<VasProvider>[]) List<VasProvider> providers,
    @Default(<VasOption>[]) List<VasOption> options,
    Account? account,
    VasProvider? provider,
    VasOption? option,
    @Default('') String recipient,
    String? recipientError,
    Failure? failure,
    VasReceipt? receipt,
  }) = _VasState;
}
