import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/domain/usecases/profile_usecases.dart';

part 'settings_cubit.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(ThemePreference.system) ThemePreference theme,
    @Default(BiometricStatus.off) BiometricStatus biometrics,
    String? error,
  }) = _SettingsState;
}

@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getTheme,
    this._saveTheme,
    this._getBiometrics,
    this._setBiometrics,
    this._authenticate,
  ) : super(const SettingsState());

  final GetThemePreference _getTheme;
  final SaveThemePreference _saveTheme;
  final GetBiometricStatus _getBiometrics;
  final SetBiometricsEnabled _setBiometrics;
  final AuthenticateWithBiometrics _authenticate;

  Future<void> load() async {
    final theme = await _getTheme(const NoParams());
    final biometrics = await _getBiometrics(const NoParams());
    emit(
      state.copyWith(
        theme: theme.getOrElse((_) => ThemePreference.system),
        biometrics: biometrics.getOrElse((_) => BiometricStatus.off),
      ),
    );
  }

  Future<void> setTheme(ThemePreference theme) async {
    emit(state.copyWith(theme: theme, error: null));
    final saved = await _saveTheme(theme);
    saved.match(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {},
    );
  }

  Future<void> setBiometrics({required bool enabled}) async {
    emit(state.copyWith(error: null));
    if (enabled) {
      final check = await _authenticate('Turn on biometric unlock');
      if (check.isLeft()) {
        emit(state.copyWith(error: check.getLeft().toNullable()?.message));
        return;
      }
    }
    final saved = await _setBiometrics(enabled);
    saved.match(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(
        state.copyWith(
          biometrics: BiometricStatus(
            available: state.biometrics.available,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}
