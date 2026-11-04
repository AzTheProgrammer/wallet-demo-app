import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/mock/fixture_loader.dart';
import 'package:wallet_app/core/mock/mock_ledger.dart';
import 'package:wallet_app/core/mock/mock_server.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late DemoConfig config;
  late MockFixtureLoader fixtures;
  late MockClock clock;
  late MockServer server;

  setUp(() {
    config = DemoConfig()
      ..failureRate = 0
      ..minLatency = Duration.zero
      ..maxLatency = Duration.zero;
    fixtures = MockFixtureLoader();
    clock = MockClock();
    when(() => clock.now()).thenReturn(fixedNow);
    server = MockServer(config, fixtures, clock);
  });

  group('respond', () {
    test('returns the handler result', () async {
      expect(await server.respond(() => 7), 7);
    });

    test('throws when offline', () {
      config.offline = true;
      expect(() => server.respond(() => 7), throwsA(isA<OfflineException>()));
    });

    test('throws when the failure rate is hit', () {
      config.failureRate = 1;
      expect(() => server.respond(() => 7), throwsA(isA<ServerException>()));
    });

    test('waits within the latency window', () async {
      config
        ..minLatency = const Duration(milliseconds: 1)
        ..maxLatency = const Duration(milliseconds: 3);
      expect(await server.respond(() => 7), 7);
    });
  });

  group('tables', () {
    test('loads a fixture once and keeps edits', () async {
      when(() => fixtures.load('rows')).thenAnswer(
        (_) async => [
          <String, dynamic>{'id': 1},
        ],
      );
      final rows = await server.table('rows');
      rows.first['id'] = 2;
      expect((await server.table('rows')).first['id'], 2);
      verify(() => fixtures.load('rows')).called(1);
    });

    test('loads a document once', () async {
      when(
        () => fixtures.load('doc'),
      ).thenAnswer((_) async => <String, dynamic>{'id': 1});
      await server.document('doc');
      expect((await server.document('doc'))['id'], 1);
      verify(() => fixtures.load('doc')).called(1);
    });
  });

  test('nextId uses the prefix', () {
    expect(server.nextId('txn'), startsWith('txn-'));
  });

  group('MockLedger', () {
    late MockLedger ledger;

    setUp(() {
      ledger = MockLedger(server);
      when(() => fixtures.load('accounts')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'acc',
            'name': 'Everyday',
            'balance_cents': 1000,
          },
        ],
      );
      when(
        () => fixtures.load('transactions'),
      ).thenAnswer((_) async => <dynamic>[]);
    });

    test('debits, records and notifies', () async {
      final changed = expectLater(server.ledgerChanges, emits(null));
      final entry = await ledger.debit(
        accountId: 'acc',
        amountCents: 400,
        title: 'Coffee',
        type: 'payment',
        reference: 'R1',
      );
      expect(entry['amount_cents'], -400);
      expect((await server.table('accounts')).first['balance_cents'], 600);
      expect((await server.table('transactions')).first['title'], 'Coffee');
      await changed;
    });

    test('refuses to overdraw', () {
      expect(
        () => ledger.debit(
          accountId: 'acc',
          amountCents: 1001,
          title: 'Too much',
          type: 'payment',
          reference: 'R2',
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('rejects an unknown account', () {
      expect(
        () => ledger.debit(
          accountId: 'nope',
          amountCents: 1,
          title: 'x',
          type: 'payment',
          reference: 'R3',
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  test('asset loader reads bundled fixtures', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await AssetFixtureLoader().load('accounts'), isA<List<dynamic>>());
  });
}
