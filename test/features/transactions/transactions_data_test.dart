import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:wallet_app/features/transactions/data/models/transaction_model.dart';
import 'package:wallet_app/features/transactions/data/models/transaction_page_model.dart';
import 'package:wallet_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/transactions/domain/usecases/transaction_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements TransactionRemoteDataSource {}

Map<String, dynamic> row(
  String id,
  String title,
  String type,
  int daysAgo, {
  String reference = 'REF',
}) => {
  'id': id,
  'title': title,
  'type': type,
  'amount_cents': -100,
  'days_ago': daysAgo,
  'status': 'completed',
  'reference': reference,
};

void main() {
  setUpAll(() => registerFallbackValue(const TransactionQuery()));

  group('use cases', () {
    late MockTransactionRepository repository;

    setUp(() => repository = MockTransactionRepository());

    test('GetTransactions passes the query', () async {
      when(
        () => repository.getTransactions(any()),
      ).thenAnswer((_) async => right(firstPage));
      expect(
        await GetTransactions(repository)(const TransactionQuery()),
        right<Failure, TransactionPage>(firstPage),
      );
    });

    test('GetRecentTransactions asks for one page of the count', () async {
      when(
        () => repository.getTransactions(const TransactionQuery(pageSize: 2)),
      ).thenAnswer((_) async => right(firstPage));
      final result = await GetRecentTransactions(repository)(2);
      expect(result.getOrElse((_) => []), firstPage.items);
    });

    test('GetRecentTransactions passes failures', () async {
      when(
        () => repository.getTransactions(any()),
      ).thenAnswer((_) async => left(const OfflineFailure()));
      expect((await GetRecentTransactions(repository)(2)).isLeft(), isTrue);
    });

    test('GetTransactionById passes the id', () async {
      when(
        () => repository.getTransaction('txn-1'),
      ).thenAnswer((_) async => right(payment));
      expect(
        await GetTransactionById(repository)('txn-1'),
        right<Failure, Transaction>(payment),
      );
    });

    test('WatchLedgerChanges exposes the stream', () {
      when(
        () => repository.watchChanges(),
      ).thenAnswer((_) => const Stream.empty());
      expect(WatchLedgerChanges(repository)(), emitsDone);
    });
  });

  group('repository', () {
    late MockRemote remote;
    late TransactionRepositoryImpl repository;

    final model = TransactionModel(
      id: 'txn-1',
      title: 'Coffee',
      type: TransactionType.payment,
      amountCents: -100,
      occurredAt: fixedNow,
      status: TransactionStatus.completed,
      reference: 'R',
    );

    setUp(() {
      remote = MockRemote();
      repository = TransactionRepositoryImpl(remote);
    });

    test('maps a page to entities', () async {
      when(() => remote.getTransactions(any())).thenAnswer(
        (_) async => TransactionPageModel(items: [model], hasMore: true),
      );
      final result = await repository.getTransactions(const TransactionQuery());
      final page = result.getOrElse((_) => throw StateError('left'));
      expect(page.items.single.title, 'Coffee');
      expect(page.hasMore, isTrue);
    });

    test('maps failures', () async {
      when(
        () => remote.getTransactions(any()),
      ).thenThrow(const OfflineException());
      expect(
        await repository.getTransactions(const TransactionQuery()),
        left<Failure, TransactionPage>(const OfflineFailure()),
      );
    });

    test('maps a single transaction', () async {
      when(() => remote.getTransaction('txn-1')).thenAnswer((_) async => model);
      final result = await repository.getTransaction('txn-1');
      expect(result.isRight(), isTrue);
    });

    test('maps a missing transaction', () async {
      when(
        () => remote.getTransaction('nope'),
      ).thenThrow(const NotFoundException());
      expect(
        await repository.getTransaction('nope'),
        left<Failure, Transaction>(const NotFoundFailure()),
      );
    });

    test('forwards ledger changes', () {
      when(() => remote.watchChanges()).thenAnswer((_) => const Stream.empty());
      expect(repository.watchChanges(), emitsDone);
    });
  });

  group('mock data source', () {
    late MockFixtureLoader fixtures;
    late MockTransactionDataSource source;

    setUp(() {
      fixtures = MockFixtureLoader();
      final clock = MockClock();
      when(clock.now).thenReturn(fixedNow);
      final config = DemoConfig()
        ..failureRate = 0
        ..minLatency = Duration.zero
        ..maxLatency = Duration.zero;
      when(() => fixtures.load('transactions')).thenAnswer(
        (_) async => [
          row('a', 'Woolworths', 'payment', 1, reference: 'W1'),
          row('b', 'Sipho', 'transfer', 5),
          row('c', 'Vodacom airtime', 'airtime', 40),
        ],
      );
      source = MockTransactionDataSource(MockServer(config, fixtures, clock));
    });

    test('returns newest first and pages', () async {
      final first = await source.getTransactions(
        const TransactionQuery(pageSize: 2),
      );
      expect(first.items.map((item) => item.id), ['a', 'b']);
      expect(first.hasMore, isTrue);
      final second = await source.getTransactions(
        const TransactionQuery(page: 2, pageSize: 2),
      );
      expect(second.items.map((item) => item.id), ['c']);
      expect(second.hasMore, isFalse);
    });

    test('searches title and reference', () async {
      final byTitle = await source.getTransactions(
        const TransactionQuery(search: 'wool'),
      );
      expect(byTitle.items.single.id, 'a');
      final byReference = await source.getTransactions(
        const TransactionQuery(search: 'w1'),
      );
      expect(byReference.items.single.id, 'a');
    });

    test('filters by type', () async {
      final page = await source.getTransactions(
        const TransactionQuery(types: {TransactionType.airtime}),
      );
      expect(page.items.single.id, 'c');
    });

    test('filters by date range', () async {
      final page = await source.getTransactions(
        TransactionQuery(
          from: fixedNow.subtract(const Duration(days: 10)),
          to: fixedNow.subtract(const Duration(days: 2)),
        ),
      );
      expect(page.items.single.id, 'b');
    });

    test('finds by id or throws', () async {
      expect((await source.getTransaction('b')).title, 'Sipho');
      expect(
        () => source.getTransaction('nope'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('exposes ledger changes', () {
      expect(source.watchChanges(), isA<Stream<void>>());
    });
  });

  test('TransactionQuery reports active filters', () {
    expect(const TransactionQuery().hasFilters, isFalse);
    expect(const TransactionQuery(search: 'x').hasFilters, isTrue);
  });

  test('models read snake_case json', () {
    final model = TransactionModel.fromJson({
      'id': 'x',
      'title': 'T',
      'type': 'data',
      'amount_cents': 5,
      'occurred_at': '2026-01-01T00:00:00.000',
      'status': 'pending',
      'reference': 'R',
      'token': '1',
    });
    expect(model.toEntity().isIncoming, isTrue);
    expect(model.toEntity().token, '1');
  });
}
