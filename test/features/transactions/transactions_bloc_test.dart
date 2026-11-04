import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transaction_filters.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/cubit/transaction_detail_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockGetTransactions getTransactions;
  late MockWatchLedger watch;
  late MockClock clock;
  late StreamController<void> ledger;

  setUpAll(() => registerFallbackValue(const TransactionQuery()));

  setUp(() {
    getTransactions = MockGetTransactions();
    watch = MockWatchLedger();
    clock = MockClock();
    ledger = StreamController<void>.broadcast();
    when(() => clock.now()).thenReturn(fixedNow);
    when(() => watch()).thenAnswer((_) => ledger.stream);
    when(
      () => getTransactions(any()),
    ).thenAnswer((_) async => right(firstPage));
  });

  tearDown(() => ledger.close());

  TransactionsBloc build() => TransactionsBloc(getTransactions, clock, watch);

  final loaded = TransactionsState(
    status: ViewStatus.success,
    items: firstPage.items,
    hasMore: true,
  );

  group('TransactionsBloc', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'loads the first page',
      build: build,
      act: (bloc) => bloc.add(const TransactionsEvent.started()),
      expect: () => [
        const TransactionsState(status: ViewStatus.loading),
        loaded,
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'shows a failure when the first page fails',
      setUp: () => when(
        () => getTransactions(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      act: (bloc) => bloc.add(const TransactionsEvent.started()),
      expect: () => [
        const TransactionsState(status: ViewStatus.loading),
        const TransactionsState(
          status: ViewStatus.failure,
          failure: OfflineFailure(),
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'appends the next page',
      setUp: () => when(
        () => getTransactions(const TransactionQuery(page: 2)),
      ).thenAnswer((_) async => right(lastPage)),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const TransactionsEvent.nextPageRequested()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          items: [...firstPage.items, ...lastPage.items],
          hasMore: false,
          page: 2,
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'keeps the list when the next page fails',
      setUp: () => when(
        () => getTransactions(const TransactionQuery(page: 2)),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const TransactionsEvent.nextPageRequested()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(nextPageFailure: const ServerFailure()),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'ignores next page when nothing is left or the list is not ready',
      build: build,
      seed: () =>
          const TransactionsState(status: ViewStatus.loading, hasMore: true),
      act: (bloc) => bloc.add(const TransactionsEvent.nextPageRequested()),
      expect: () => <TransactionsState>[],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'debounces search and queries the last value',
      build: build,
      act: (bloc) {
        bloc
          ..add(const TransactionsEvent.searchChanged('w'))
          ..add(const TransactionsEvent.searchChanged('wool'));
      },
      wait: TransactionsBloc.searchDebounce * 2,
      expect: () => [
        const TransactionsState(status: ViewStatus.loading, search: 'wool'),
        loaded.copyWith(search: 'wool'),
      ],
      verify: (_) => verify(
        () => getTransactions(const TransactionQuery(search: 'wool')),
      ).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'applies type and date filters',
      build: build,
      act: (bloc) => bloc.add(
        const TransactionsEvent.filtersChanged(
          TransactionFilters(
            types: {TransactionType.data},
            range: DateRangeFilter.week,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.isFiltered, isTrue);
        verify(
          () => getTransactions(
            TransactionQuery(
              types: const {TransactionType.data},
              from: fixedNow.subtract(const Duration(days: 7)),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'refreshes without a loading state and keeps data on failure',
      setUp: () => when(
        () => getTransactions(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const TransactionsEvent.refreshed()),
      expect: () => <TransactionsState>[],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reloads when the ledger changes',
      build: build,
      act: (_) => ledger.add(null),
      wait: Duration.zero,
      expect: () => [loaded],
    );
  });

  group('TransactionDetailCubit', () {
    late MockGetTransactionById getById;

    setUp(() => getById = MockGetTransactionById());

    blocTest<TransactionDetailCubit, TransactionDetailState>(
      'uses the transaction it was given',
      build: () => TransactionDetailCubit(getById),
      act: (cubit) => cubit.load('txn-1', initial: payment),
      expect: () => [
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: payment,
        ),
      ],
      verify: (_) => verifyNever(() => getById(any())),
    );

    blocTest<TransactionDetailCubit, TransactionDetailState>(
      'fetches by id',
      setUp: () =>
          when(() => getById('txn-1')).thenAnswer((_) async => right(payment)),
      build: () => TransactionDetailCubit(getById),
      act: (cubit) => cubit.load('txn-1'),
      expect: () => [
        const TransactionDetailState(status: ViewStatus.loading),
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: payment,
        ),
      ],
    );

    blocTest<TransactionDetailCubit, TransactionDetailState>(
      'reports failures',
      setUp: () => when(
        () => getById('nope'),
      ).thenAnswer((_) async => left(const NotFoundFailure())),
      build: () => TransactionDetailCubit(getById),
      act: (cubit) => cubit.load('nope'),
      expect: () => [
        const TransactionDetailState(status: ViewStatus.loading),
        const TransactionDetailState(
          status: ViewStatus.failure,
          failure: NotFoundFailure(),
        ),
      ],
    );
  });

  test('filters count active choices', () {
    expect(const TransactionFilters().activeCount, 0);
    expect(
      const TransactionFilters(
        types: {TransactionType.data},
        range: DateRangeFilter.month,
      ).activeCount,
      2,
    );
  });
}
