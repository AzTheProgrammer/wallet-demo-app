import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/transactions/domain/usecases/transaction_usecases.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transaction_filters.dart';

part 'transactions_bloc.freezed.dart';
part 'transactions_event.dart';
part 'transactions_state.dart';

EventTransformer<E> _debounce<E>(Duration wait) {
  return (events, mapper) {
    Timer? timer;
    final debounced = events.transform(
      StreamTransformer<E, E>.fromHandlers(
        handleData: (event, sink) {
          timer?.cancel();
          timer = Timer(wait, () => sink.add(event));
        },
      ),
    );
    return debounced.asyncExpand(mapper);
  };
}

@injectable
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc(this._getTransactions, this._clock, WatchLedgerChanges watch)
    : super(const TransactionsState()) {
    on<TransactionsStarted>(_onStarted);
    on<TransactionsRefreshed>(_onRefreshed);
    on<NextPageRequested>(_onNextPage);
    on<SearchChanged>(
      _onSearchChanged,
      transformer: _debounce(searchDebounce),
    );
    on<FiltersChanged>(_onFiltersChanged);
    _ledger = watch().listen((_) => add(const TransactionsRefreshed()));
  }

  static const searchDebounce = Duration(milliseconds: 300);

  final GetTransactions _getTransactions;
  final AppClock _clock;
  late final StreamSubscription<void> _ledger;
  int _latestRequest = 0;

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionsState> emit,
  ) => _reload(state, emit, showLoading: true);

  Future<void> _onRefreshed(
    TransactionsRefreshed event,
    Emitter<TransactionsState> emit,
  ) => _reload(state, emit, showLoading: false);

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<TransactionsState> emit,
  ) => _reload(state.copyWith(search: event.search), emit, showLoading: true);

  Future<void> _onFiltersChanged(
    FiltersChanged event,
    Emitter<TransactionsState> emit,
  ) => _reload(state.copyWith(filters: event.filters), emit, showLoading: true);

  Future<void> _reload(
    TransactionsState base,
    Emitter<TransactionsState> emit, {
    required bool showLoading,
  }) async {
    final request = ++_latestRequest;
    if (showLoading) {
      emit(base.copyWith(status: ViewStatus.loading, failure: null));
    }
    final result = await _getTransactions(_queryFor(base, 1));
    if (request != _latestRequest) return;
    result.match(
      (failure) => emit(
        base.items.isNotEmpty && !showLoading
            ? base.copyWith(status: ViewStatus.success)
            : base.copyWith(status: ViewStatus.failure, failure: failure),
      ),
      (page) => emit(
        base.copyWith(
          status: ViewStatus.success,
          items: page.items,
          hasMore: page.hasMore,
          page: 1,
          failure: null,
          nextPageFailure: null,
        ),
      ),
    );
  }

  Future<void> _onNextPage(
    NextPageRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    if (state.status != ViewStatus.success) return;
    final request = _latestRequest;
    emit(state.copyWith(isLoadingMore: true, nextPageFailure: null));
    final next = state.page + 1;
    final result = await _getTransactions(_queryFor(state, next));
    if (request != _latestRequest) return;
    result.match(
      (failure) => emit(
        state.copyWith(isLoadingMore: false, nextPageFailure: failure),
      ),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          items: [...state.items, ...page.items],
          hasMore: page.hasMore,
          page: next,
        ),
      ),
    );
  }

  TransactionQuery _queryFor(TransactionsState source, int page) {
    final days = source.filters.range.days;
    return TransactionQuery(
      page: page,
      search: source.search,
      types: source.filters.types,
      from: days == null ? null : _clock.now().subtract(Duration(days: days)),
    );
  }

  @override
  Future<void> close() {
    unawaited(_ledger.cancel());
    return super.close();
  }
}
