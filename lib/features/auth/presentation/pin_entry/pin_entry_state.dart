part of 'pin_entry_cubit.dart';

enum PinEntryStatus { idle, verifying, success }

@freezed
abstract class PinEntryState with _$PinEntryState {
  const factory PinEntryState({
    @Default('') String entered,
    @Default(PinEntryStatus.idle) PinEntryStatus status,
    @Default(false) bool biometricsReady,
    @Default(0) int lockoutSeconds,
    String? error,
  }) = _PinEntryState;

  const PinEntryState._();

  bool get isLocked => lockoutSeconds > 0;

  bool get acceptsInput => status == PinEntryStatus.idle && !isLocked;
}
