import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';

part 'pin_setup_cubit.freezed.dart';
part 'pin_setup_state.dart';

@injectable
class PinSetupCubit extends Cubit<PinSetupState> {
  PinSetupCubit(
    this._createPin,
    this._getBiometricStatus,
    this._setBiometricsEnabled,
  ) : super(const PinSetupState());

  final CreatePin _createPin;
  final GetBiometricStatus _getBiometricStatus;
  final SetBiometricsEnabled _setBiometricsEnabled;

  Future<void> digitEntered(String digit) async {
    if (state.isSaving || state.entered.length >= PinPolicy.length) return;
    final entered = state.entered + digit;
    emit(state.copyWith(entered: entered, error: null));
    if (entered.length < PinPolicy.length) return;
    if (state.step == PinSetupStep.create) {
      _acceptFirstPin(entered);
    } else {
      await _confirm(entered);
    }
  }

  void backspace() {
    if (state.isSaving || state.entered.isEmpty) return;
    emit(
      state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
      ),
    );
  }

  Future<void> chooseBiometrics({required bool enable}) async {
    if (enable) await _setBiometricsEnabled(true);
    emit(state.copyWith(step: PinSetupStep.done));
  }

  void _acceptFirstPin(String pin) {
    final problem = PinPolicy.validate(pin);
    if (problem != null) {
      emit(state.copyWith(entered: '', error: problem));
      return;
    }
    emit(
      state.copyWith(step: PinSetupStep.confirm, entered: '', firstPin: pin),
    );
  }

  Future<void> _confirm(String pin) async {
    if (pin != state.firstPin) {
      emit(
        const PinSetupState(error: "Those PINs didn't match. Start again."),
      );
      return;
    }
    emit(state.copyWith(isSaving: true));
    final result = await _createPin(pin);
    await result.match(
      (failure) async => emit(
        state.copyWith(entered: '', isSaving: false, error: failure.message),
      ),
      (_) => _afterPinSaved(),
    );
  }

  Future<void> _afterPinSaved() async {
    final status = await _getBiometricStatus(const NoParams());
    final canOffer = status.match((_) => false, (value) => value.available);
    emit(
      state.copyWith(
        entered: '',
        isSaving: false,
        step: canOffer ? PinSetupStep.biometrics : PinSetupStep.done,
      ),
    );
  }
}
