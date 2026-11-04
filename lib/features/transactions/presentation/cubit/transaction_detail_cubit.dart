import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/usecases/transaction_usecases.dart';

part 'transaction_detail_cubit.freezed.dart';

@freezed
abstract class TransactionDetailState with _$TransactionDetailState {
  const factory TransactionDetailState({
    @Default(ViewStatus.initial) ViewStatus status,
    Transaction? transaction,
    Failure? failure,
  }) = _TransactionDetailState;
}

@injectable
class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  TransactionDetailCubit(this._getTransaction)
    : super(const TransactionDetailState());

  final GetTransactionById _getTransaction;

  Future<void> load(String id, {Transaction? initial}) async {
    if (initial != null) {
      emit(
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: initial,
        ),
      );
      return;
    }
    emit(const TransactionDetailState(status: ViewStatus.loading));
    final result = await _getTransaction(id);
    result.match(
      (failure) => emit(
        TransactionDetailState(status: ViewStatus.failure, failure: failure),
      ),
      (transaction) => emit(
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: transaction,
        ),
      ),
    );
  }
}
