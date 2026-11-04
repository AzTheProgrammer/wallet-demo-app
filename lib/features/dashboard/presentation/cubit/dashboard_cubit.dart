import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/usecases/get_accounts.dart';
import 'package:wallet_app/features/profile/domain/usecases/profile_usecases.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/usecases/transaction_usecases.dart';

part 'dashboard_cubit.freezed.dart';
part 'dashboard_state.dart';

@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._getAccounts,
    this._getRecent,
    this._getProfile,
    WatchLedgerChanges watchLedger,
  ) : super(const DashboardState()) {
    _ledger = watchLedger().listen((_) => refresh());
  }

  static const recentCount = 5;

  final GetAccounts _getAccounts;
  final GetRecentTransactions _getRecent;
  final GetProfile _getProfile;
  late final StreamSubscription<void> _ledger;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, failure: null));
    await _fetch();
  }

  Future<void> refresh() async {
    emit(state.copyWith(refreshFailure: null));
    await _fetch();
  }

  Future<void> _fetch() async {
    final results = await Future.wait([
      _getAccounts(const NoParams()),
      _getRecent(recentCount),
    ]);
    if (isClosed) return;
    final accounts = results[0] as Either<Failure, List<Account>>;
    final recent = results[1] as Either<Failure, List<Transaction>>;
    final failure =
        accounts.getLeft().toNullable() ?? recent.getLeft().toNullable();
    if (failure != null) {
      _emitFailure(failure);
      return;
    }
    final profile = await _getProfile(const NoParams());
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ViewStatus.success,
        accounts: accounts.getOrElse((_) => const []),
        recent: recent.getOrElse((_) => const []),
        firstName: profile.match((_) => state.firstName, (p) => p.firstName),
        failure: null,
      ),
    );
  }

  void _emitFailure(Failure failure) {
    if (state.accounts.isNotEmpty) {
      emit(
        state.copyWith(status: ViewStatus.success, refreshFailure: failure),
      );
    } else {
      emit(state.copyWith(status: ViewStatus.failure, failure: failure));
    }
  }

  @override
  Future<void> close() {
    unawaited(_ledger.cancel());
    return super.close();
  }
}
