part of 'transactions_bloc.dart';

@freezed
sealed class TransactionsEvent with _$TransactionsEvent {
  const factory TransactionsEvent.started() = TransactionsStarted;
  const factory TransactionsEvent.refreshed() = TransactionsRefreshed;
  const factory TransactionsEvent.nextPageRequested() = NextPageRequested;
  const factory TransactionsEvent.searchChanged(String search) = SearchChanged;
  const factory TransactionsEvent.filtersChanged(TransactionFilters filters) =
      FiltersChanged;
}
