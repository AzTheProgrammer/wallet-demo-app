import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/domain/usecases/profile_usecases.dart';

part 'profile_cubit.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(ViewStatus.initial) ViewStatus status,
    Profile? profile,
    @Default(false) bool isSaving,
    @Default(false) bool saved,
    Failure? failure,
    Failure? saveFailure,
  }) = _ProfileState;
}

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfile, this._updateProfile)
    : super(const ProfileState());

  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, failure: null));
    final result = await _getProfile(const NoParams());
    result.match(
      (failure) =>
          emit(state.copyWith(status: ViewStatus.failure, failure: failure)),
      (profile) =>
          emit(state.copyWith(status: ViewStatus.success, profile: profile)),
    );
  }

  Future<void> save({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final current = state.profile;
    if (current == null) return;
    emit(state.copyWith(isSaving: true, saved: false, saveFailure: null));
    final result = await _updateProfile(
      current.copyWith(fullName: fullName, email: email, phone: phone),
    );
    result.match(
      (failure) => emit(state.copyWith(isSaving: false, saveFailure: failure)),
      (profile) => emit(
        state.copyWith(isSaving: false, saved: true, profile: profile),
      ),
    );
  }
}
