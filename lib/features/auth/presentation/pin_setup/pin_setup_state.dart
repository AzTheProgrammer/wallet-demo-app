part of 'pin_setup_cubit.dart';

enum PinSetupStep { create, confirm, biometrics, done }

@freezed
abstract class PinSetupState with _$PinSetupState {
  const factory PinSetupState({
    @Default(PinSetupStep.create) PinSetupStep step,
    @Default('') String entered,
    @Default('') String firstPin,
    @Default(false) bool isSaving,
    String? error,
  }) = _PinSetupState;
}
