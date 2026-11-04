import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';

part 'change_pin_cubit.freezed.dart';
part 'change_pin_state.dart';

@injectable
class ChangePinCubit extends Cubit<ChangePinState> {
  ChangePinCubit(this._changePin) : super(const ChangePinState());

  final ChangePin _changePin;

  Future<void> digitEntered(String digit) async {
    if (state.isSaving || state.entered.length >= PinPolicy.length) return;
    final entered = state.entered + digit;
    emit(state.copyWith(entered: entered, error: null));
    if (entered.length < PinPolicy.length) return;
    switch (state.step) {
      case ChangePinStep.current:
        emit(
          state.copyWith(
            step: ChangePinStep.next,
            currentPin: entered,
            entered: '',
          ),
        );
      case ChangePinStep.next:
        _acceptNext(entered);
      case ChangePinStep.confirm:
        await _save(entered);
      case ChangePinStep.done:
        break;
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

  void _acceptNext(String pin) {
    final problem = PinPolicy.validate(pin);
    if (problem != null) {
      emit(state.copyWith(entered: '', error: problem));
      return;
    }
    emit(
      state.copyWith(step: ChangePinStep.confirm, nextPin: pin, entered: ''),
    );
  }

  Future<void> _save(String pin) async {
    if (pin != state.nextPin) {
      emit(
        state.copyWith(
          step: ChangePinStep.next,
          entered: '',
          nextPin: '',
          error: "Those PINs didn't match. Enter your new PIN again.",
        ),
      );
      return;
    }
    emit(state.copyWith(isSaving: true));
    final result = await _changePin(
      ChangePinParams(current: state.currentPin, next: pin),
    );
    result.match(
      (failure) => emit(
        ChangePinState(error: failure.message),
      ),
      (_) => emit(
        state.copyWith(step: ChangePinStep.done, isSaving: false, entered: ''),
      ),
    );
  }
}
