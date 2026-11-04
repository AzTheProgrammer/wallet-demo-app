part of 'change_pin_cubit.dart';

enum ChangePinStep { current, next, confirm, done }

@freezed
abstract class ChangePinState with _$ChangePinState {
  const factory ChangePinState({
    @Default(ChangePinStep.current) ChangePinStep step,
    @Default('') String entered,
    @Default('') String currentPin,
    @Default('') String nextPin,
    @Default(false) bool isSaving,
    String? error,
  }) = _ChangePinState;
}
