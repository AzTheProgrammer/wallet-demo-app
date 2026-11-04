part of 'transactions_bloc.dart';

@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Transaction>[]) List<Transaction> items,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(1) int page,
    @Default('') String search,
    @Default(TransactionFilters()) TransactionFilters filters,
    Failure? failure,
    Failure? nextPageFailure,
  }) = _TransactionsState;

  const TransactionsState._();

  bool get isFiltered => search.isNotEmpty || filters.activeCount > 0;
}
