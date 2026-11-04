import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/dashboard/data/datasources/account_remote_data_source.dart';
import 'package:wallet_app/features/dashboard/data/models/account_model.dart';
import 'package:wallet_app/features/dashboard/data/repositories/account_repository_impl.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/usecases/get_accounts.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements AccountRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  test('GetAccounts passes through', () async {
    final repository = MockAccountRepository();
    when(
      repository.getAccounts,
    ).thenAnswer((_) async => right(const [mainAccount]));
    final result = await GetAccounts(repository)(const NoParams());
    expect(result.getOrElse((_) => []), [mainAccount]);
  });

  test('Account masks its number', () {
    expect(mainAccount.maskedNumber, '•••• 7291');
  });

  group('AccountRepositoryImpl', () {
    late MockRemote remote;

    setUp(() => remote = MockRemote());

    test('maps models to entities', () async {
      when(() => remote.getAccounts()).thenAnswer(
        (_) async => [
          const AccountModel(
            id: 'acc-main',
            name: 'Everyday account',
            kind: AccountKind.main,
            balanceCents: 1842675,
            number: '62018847291',
          ),
        ],
      );
      final result = await AccountRepositoryImpl(remote).getAccounts();
      expect(result.getOrElse((_) => []), [mainAccount]);
    });

    test('maps failures', () async {
      when(() => remote.getAccounts()).thenThrow(const OfflineException());
      final result = await AccountRepositoryImpl(remote).getAccounts();
      expect(result.getLeft().toNullable(), const OfflineFailure());
    });
  });

  test('MockAccountDataSource reads the fixture', () async {
    final fixtures = MockFixtureLoader();
    when(() => fixtures.load('accounts')).thenAnswer(
      (_) async => [
        <String, dynamic>{
          'id': 'a',
          'name': 'Main',
          'kind': 'main',
          'balance_cents': 5,
          'number': '1234',
        },
      ],
    );
    final config = DemoConfig()
      ..failureRate = 0
      ..minLatency = Duration.zero
      ..maxLatency = Duration.zero;
    final source = MockAccountDataSource(
      MockServer(config, fixtures, MockClock()),
    );
    expect((await source.getAccounts()).single.balanceCents, 5);
  });

  group('DashboardCubit', () {
    late MockGetAccounts accounts;
    late MockGetRecent recent;
    late MockGetProfile profile;
    late MockWatchLedger watch;
    late StreamController<void> ledger;

    setUp(() {
      accounts = MockGetAccounts();
      recent = MockGetRecent();
      profile = MockGetProfile();
      watch = MockWatchLedger();
      ledger = StreamController<void>.broadcast();
      when(() => watch()).thenAnswer((_) => ledger.stream);
      when(
        () => accounts(any()),
      ).thenAnswer((_) async => right(const [mainAccount]));
      when(
        () => recent(any()),
      ).thenAnswer((_) async => right([payment]));
      when(() => profile(any())).thenAnswer((_) async => right(thandi));
    });

    tearDown(() => ledger.close());

    DashboardCubit build() => DashboardCubit(accounts, recent, profile, watch);

    final loaded = DashboardState(
      status: ViewStatus.success,
      accounts: const [mainAccount],
      recent: [payment],
      firstName: 'Thandi',
    );

    blocTest<DashboardCubit, DashboardState>(
      'loads accounts, activity and the name',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const DashboardState(status: ViewStatus.loading), loaded],
    );

    blocTest<DashboardCubit, DashboardState>(
      'shows a failure when there is nothing to show',
      setUp: () => when(
        () => accounts(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const DashboardState(status: ViewStatus.loading),
        const DashboardState(
          status: ViewStatus.failure,
          failure: OfflineFailure(),
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'fails when recent activity fails',
      setUp: () => when(
        () => recent(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.status, ViewStatus.failure),
    );

    blocTest<DashboardCubit, DashboardState>(
      'keeps data and flags a failed refresh',
      setUp: () => when(
        () => accounts(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        loaded.copyWith(refreshFailure: const OfflineFailure()),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'still loads when the profile fails',
      setUp: () => when(
        () => profile(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, ViewStatus.success);
        expect(cubit.state.firstName, isEmpty);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'refreshes when the ledger changes',
      build: build,
      act: (_) => ledger.add(null),
      wait: Duration.zero,
      verify: (_) => verify(() => accounts(any())).called(1),
    );
  });
}
