import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';

part 'pin_entry_cubit.freezed.dart';
part 'pin_entry_state.dart';

@injectable
class PinEntryCubit extends Cubit<PinEntryState> {
  PinEntryCubit(
    this._verifyPin,
    this._getLockout,
    this._getBiometricStatus,
    this._authenticate,
    this._clock,
  ) : super(const PinEntryState());

  final VerifyPin _verifyPin;
  final GetLockout _getLockout;
  final GetBiometricStatus _getBiometricStatus;
  final AuthenticateWithBiometrics _authenticate;
  final AppClock _clock;
  Timer? _ticker;

  Future<void> start({required String biometricReason}) async {
    final lockout = await _getLockout(const NoParams());
    lockout.match((_) {}, (until) {
      if (until != null) _startLockout(until);
    });
    final biometrics = await _getBiometricStatus(const NoParams());
    final ready = biometrics.match((_) => false, (status) => status.canUse);
    emit(state.copyWith(biometricsReady: ready));
    if (ready && !state.isLocked) await useBiometrics(biometricReason);
  }

  Future<void> digitEntered(String digit) async {
    if (!state.acceptsInput || state.entered.length >= PinPolicy.length) return;
    final entered = state.entered + digit;
    emit(state.copyWith(entered: entered, error: null));
    if (entered.length == PinPolicy.length) await _submit(entered);
  }

  void backspace() {
    if (!state.acceptsInput || state.entered.isEmpty) return;
    emit(
      state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
        error: null,
      ),
    );
  }

  Future<void> useBiometrics(String reason) async {
    if (!state.acceptsInput || !state.biometricsReady) return;
    final result = await _authenticate(reason);
    result.match(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(status: PinEntryStatus.success, error: null)),
    );
  }

  Future<void> _submit(String pin) async {
    emit(state.copyWith(status: PinEntryStatus.verifying));
    final result = await _verifyPin(pin);
    result.match(
      _handleFailure,
      (_) => emit(state.copyWith(status: PinEntryStatus.success)),
    );
  }

  void _handleFailure(Failure failure) {
    emit(
      state.copyWith(
        entered: '',
        status: PinEntryStatus.idle,
        error: failure.message,
      ),
    );
    if (failure is LockedOutFailure) _startLockout(failure.until);
  }

  void _startLockout(DateTime until) {
    _tick(until);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick(until));
  }

  void _tick(DateTime until) {
    final remaining = until.difference(_clock.now()).inSeconds + 1;
    if (remaining <= 0 || !until.isAfter(_clock.now())) {
      _ticker?.cancel();
      emit(state.copyWith(lockoutSeconds: 0, error: null));
      return;
    }
    emit(state.copyWith(lockoutSeconds: remaining));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
