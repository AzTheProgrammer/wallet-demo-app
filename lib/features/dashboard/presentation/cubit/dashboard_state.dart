part of 'dashboard_cubit.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Account>[]) List<Account> accounts,
    @Default(<Transaction>[]) List<Transaction> recent,
    @Default('') String firstName,
    Failure? failure,
    Failure? refreshFailure,
  }) = _DashboardState;
}
