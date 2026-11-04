import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transaction_filters.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transactions_page.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/filter_sheet.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_visuals.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => registerFallbackValue(const TransactionsEvent.started()));

  group('TransactionsPage', () {
    late MockTransactionsBloc bloc;

    setUp(() => bloc = MockTransactionsBloc());

    final loaded = TransactionsState(
      status: ViewStatus.success,
      items: firstPage.items,
      hasMore: true,
    );

    Future<void> pump(WidgetTester tester) => tester.pumpRouted(
      BlocProvider<TransactionsBloc>.value(
        value: bloc,
        child: const TransactionsPage(),
      ),
    );

    testWidgets('shows a skeleton while loading', (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(const TransactionsState(status: ViewStatus.loading));
      await pump(tester);
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('lists transactions', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      expect(find.byType(TransactionTile), findsNWidgets(2));
      expect(find.textContaining('+R'), findsOneWidget);
    });

    testWidgets('has an empty state', (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(const TransactionsState(status: ViewStatus.success));
      await pump(tester);
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('has a no-results state', (tester) async {
      when(() => bloc.state).thenReturn(
        const TransactionsState(status: ViewStatus.success, search: 'x'),
      );
      await pump(tester);
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('retries after a failure', (tester) async {
      when(() => bloc.state).thenReturn(
        const TransactionsState(
          status: ViewStatus.failure,
          failure: ServerFailure(),
        ),
      );
      await pump(tester);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const TransactionsEvent.started())).called(1);
    });

    testWidgets('typing searches', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), 'wool');
      verify(
        () => bloc.add(const TransactionsEvent.searchChanged('wool')),
      ).called(1);
    });

    testWidgets('scrolling asks for the next page', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -50));
      await tester.pump();
      verify(
        () => bloc.add(const TransactionsEvent.nextPageRequested()),
      ).called(greaterThan(0));
    });

    testWidgets('shows next page loading and failure footers', (tester) async {
      when(() => bloc.state).thenReturn(loaded.copyWith(isLoadingMore: true));
      await pump(tester);
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('retries a failed next page', (tester) async {
      when(() => bloc.state).thenReturn(
        loaded.copyWith(nextPageFailure: const ServerFailure()),
      );
      await pump(tester);
      await tester.tap(find.text('Load more failed. Try again'));
      verify(
        () => bloc.add(const TransactionsEvent.nextPageRequested()),
      ).called(1);
    });

    testWidgets('pull to refresh reloads', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      verify(() => bloc.add(const TransactionsEvent.refreshed())).called(1);
    });

    testWidgets('applies filters from the sheet', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Airtime'));
      await tester.tap(find.text('Last 7 days'));
      await tester.pump();
      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(
          const TransactionsEvent.filtersChanged(
            TransactionFilters(
              types: {TransactionType.airtime},
              range: DateRangeFilter.week,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('dismissing the sheet changes nothing', (tester) async {
      when(() => bloc.state).thenReturn(loaded);
      await pump(tester);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });
  });

  group('FilterSheet', () {
    testWidgets('clears and toggles choices', (tester) async {
      TransactionFilters? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<TransactionFilters>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FilterSheet(
                  initial: TransactionFilters(
                    types: {TransactionType.data},
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data'));
      await tester.pump();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(result, const TransactionFilters());
    });
  });

  group('TransactionDetailPage', () {
    late MockTransactionDetailCubit cubit;

    setUp(() => cubit = MockTransactionDetailCubit());

    Future<void> pump(WidgetTester tester) => tester.pumpApp(
      BlocProvider<TransactionDetailCubit>.value(
        value: cubit,
        child: const TransactionDetailPage(
          transactionId: 'txn-1',
          heroTag: 'home-txn-1',
        ),
      ),
    );

    testWidgets('shows a skeleton while loading', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const TransactionDetailState(status: ViewStatus.loading));
      await pump(tester);
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('shows details', (tester) async {
      when(() => cubit.state).thenReturn(
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: payment,
        ),
      );
      await pump(tester);
      expect(find.text('Woolworths Food'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Everyday account'), findsOneWidget);
      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('labels pending and failed payments', (tester) async {
      when(() => cubit.state).thenReturn(
        TransactionDetailState(status: ViewStatus.success, transaction: salary),
      );
      await pump(tester);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows and copies an electricity token', (tester) async {
      when(() => cubit.state).thenReturn(
        TransactionDetailState(
          status: ViewStatus.success,
          transaction: electricity,
        ),
      );
      await pump(tester);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text(groupToken(electricity.token!)), findsOneWidget);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      await tester.pump();
      expect(find.text('Token copied'), findsOneWidget);
    });

    testWidgets('retries a failure', (tester) async {
      when(() => cubit.state).thenReturn(
        const TransactionDetailState(
          status: ViewStatus.failure,
          failure: NotFoundFailure(),
        ),
      );
      when(() => cubit.load(any())).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('Try again'));
      verify(() => cubit.load('txn-1')).called(1);
    });
  });

  test('every type has an icon', () {
    final icons = TransactionType.values.map(transactionIcon).toSet();
    expect(icons, hasLength(TransactionType.values.length));
  });
}
