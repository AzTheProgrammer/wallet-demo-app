import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/mock/mock_ledger.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/vas/data/datasources/vas_remote_data_source.dart';
import 'package:wallet_app/features/vas/data/models/vas_models.dart';
import 'package:wallet_app/features/vas/data/repositories/vas_repository_impl.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/domain/usecases/vas_usecases.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements VasRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(airtimePurchase);
    registerFallbackValue(VasKind.airtime);
    registerFallbackValue(
      const VasOptionsParams(kind: VasKind.airtime, providerId: ''),
    );
  });

  group('use cases', () {
    late MockVasRepository repository;

    setUp(() => repository = MockVasRepository());

    test('GetVasProviders passes the kind', () async {
      when(
        () => repository.getProviders(VasKind.data),
      ).thenAnswer((_) async => right(const [vodacom]));
      final result = await GetVasProviders(repository)(VasKind.data);
      expect(result.getOrElse((_) => []), [vodacom]);
    });

    test('GetVasOptions passes kind and provider', () async {
      when(
        () => repository.getOptions(VasKind.airtime, 'vodacom'),
      ).thenAnswer((_) async => right(const [airtimeOption]));
      final result = await GetVasOptions(repository)(
        const VasOptionsParams(kind: VasKind.airtime, providerId: 'vodacom'),
      );
      expect(result.getOrElse((_) => []), [airtimeOption]);
    });

    test('PurchaseVas buys for a valid number', () async {
      when(
        () => repository.purchase(airtimePurchase),
      ).thenAnswer((_) async => right(airtimeReceipt));
      expect(
        await PurchaseVas(repository)(airtimePurchase),
        right<Failure, VasReceipt>(airtimeReceipt),
      );
    });

    test('PurchaseVas rejects a bad meter', () async {
      final result = await PurchaseVas(repository)(
        const VasPurchase(
          kind: VasKind.electricity,
          provider: cityPower,
          option: electricityOption,
          recipient: '123',
          accountId: 'acc-main',
        ),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.purchase(any()));
    });
  });

  group('repository', () {
    late MockRemote remote;
    late VasRepositoryImpl repository;

    setUp(() {
      remote = MockRemote();
      repository = VasRepositoryImpl(remote);
    });

    test('maps providers', () async {
      when(() => remote.getProviders(any())).thenAnswer(
        (_) async => const [
          VasProviderModel(
            id: 'vodacom',
            name: 'Vodacom',
            kinds: [VasKind.airtime],
          ),
        ],
      );
      final result = await repository.getProviders(VasKind.airtime);
      expect(result.getOrElse((_) => []), [vodacom]);
    });

    test('maps options', () async {
      when(() => remote.getOptions(VasKind.airtime, 'vodacom')).thenAnswer(
        (_) async => const [
          VasOptionModel(
            id: 'air-29',
            kind: VasKind.airtime,
            label: 'R29 airtime',
            amountCents: 2900,
          ),
        ],
      );
      final result = await repository.getOptions(VasKind.airtime, 'vodacom');
      expect(result.getOrElse((_) => []), [airtimeOption]);
    });

    test('maps a receipt', () async {
      when(() => remote.purchase(any())).thenAnswer(
        (_) async => VasReceiptModel(
          transactionId: 'txn-8',
          reference: 'VAS10000001',
          purchasedAt: fixedNow,
        ),
      );
      expect(
        await repository.purchase(airtimePurchase),
        right<Failure, VasReceipt>(airtimeReceipt),
      );
    });

    test('maps failures', () async {
      when(() => remote.getProviders(any())).thenThrow(const ServerException());
      final result = await repository.getProviders(VasKind.airtime);
      expect(result.isLeft(), isTrue);
    });
  });

  group('mock data source', () {
    late MockVasDataSource source;

    setUp(() {
      final fixtures = MockFixtureLoader();
      final clock = MockClock();
      when(clock.now).thenReturn(fixedNow);
      when(() => fixtures.load('vas_providers')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'vodacom',
            'name': 'Vodacom',
            'kinds': ['airtime'],
          },
          <String, dynamic>{
            'id': 'citypower',
            'name': 'City Power',
            'kinds': ['electricity'],
          },
        ],
      );
      when(() => fixtures.load('vas_options')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'a',
            'kind': 'airtime',
            'label': 'R10',
            'amount_cents': 1000,
          },
          <String, dynamic>{
            'id': 'b',
            'kind': 'data',
            'provider_id': 'mtn',
            'label': '1 GB',
            'amount_cents': 8500,
          },
        ],
      );
      when(() => fixtures.load('accounts')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'acc-main',
            'name': 'Everyday',
            'balance_cents': 1000000,
          },
        ],
      );
      when(
        () => fixtures.load('transactions'),
      ).thenAnswer((_) async => <dynamic>[]);
      final config = DemoConfig()
        ..failureRate = 0
        ..minLatency = Duration.zero
        ..maxLatency = Duration.zero;
      final server = MockServer(config, fixtures, clock);
      source = MockVasDataSource(server, MockLedger(server));
    });

    test('filters providers by kind', () async {
      final providers = await source.getProviders(VasKind.electricity);
      expect(providers.single.id, 'citypower');
    });

    test('filters options by kind and provider', () async {
      expect((await source.getOptions(VasKind.airtime, 'x')).single.id, 'a');
      expect(await source.getOptions(VasKind.data, 'x'), isEmpty);
      expect((await source.getOptions(VasKind.data, 'mtn')).single.id, 'b');
    });

    test('airtime receipts have no token', () async {
      final receipt = await source.purchase(airtimePurchase);
      expect(receipt.token, isNull);
      expect(receipt.units, isNull);
    });

    test('electricity receipts have a 20-digit token', () async {
      final receipt = await source.purchase(
        const VasPurchase(
          kind: VasKind.electricity,
          provider: cityPower,
          option: electricityOption,
          recipient: '12345678901',
          accountId: 'acc-main',
        ),
      );
      expect(receipt.token, matches(RegExp(r'^\d{20}$')));
      expect(receipt.units, '31.3 kWh');
    });
  });

  group('VasBloc', () {
    late MockGetVasProviders providers;
    late MockGetVasOptions options;
    late MockGetAccounts accounts;
    late MockPurchaseVas purchase;

    setUp(() {
      providers = MockGetVasProviders();
      options = MockGetVasOptions();
      accounts = MockGetAccounts();
      purchase = MockPurchaseVas();
      when(
        () => providers(any()),
      ).thenAnswer((_) async => right(const [vodacom]));
      when(
        () => accounts(any()),
      ).thenAnswer((_) async => right(const [mainAccount]));
      when(
        () => options(any()),
      ).thenAnswer((_) async => right(const [airtimeOption]));
    });

    VasBloc build() => VasBloc(providers, options, accounts, purchase);

    const ready = VasState(
      loadStatus: ViewStatus.success,
      providers: [vodacom],
      account: mainAccount,
    );

    const reviewing = VasState(
      loadStatus: ViewStatus.success,
      providers: [vodacom],
      account: mainAccount,
      step: VasStep.review,
      provider: vodacom,
      option: airtimeOption,
      options: [airtimeOption],
      recipient: '0825550142',
    );

    blocTest<VasBloc, VasState>(
      'loads providers for the kind',
      build: build,
      act: (bloc) => bloc.add(const VasEvent.started(VasKind.airtime)),
      expect: () => [const VasState(loadStatus: ViewStatus.loading), ready],
    );

    blocTest<VasBloc, VasState>(
      'reports a load failure',
      setUp: () => when(
        () => providers(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      act: (bloc) => bloc.add(const VasEvent.started(VasKind.data)),
      verify: (bloc) {
        expect(bloc.state.loadStatus, ViewStatus.failure);
        expect(bloc.state.kind, VasKind.data);
      },
    );

    blocTest<VasBloc, VasState>(
      'choosing a provider moves on',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const VasEvent.providerSelected(vodacom)),
      verify: (bloc) => expect(bloc.state.step, VasStep.recipient),
    );

    blocTest<VasBloc, VasState>(
      'a bad number shows an error',
      build: build,
      seed: () => ready.copyWith(step: VasStep.recipient, provider: vodacom),
      act: (bloc) => bloc
        ..add(const VasEvent.recipientChanged('123'))
        ..add(const VasEvent.recipientSubmitted()),
      verify: (bloc) {
        expect(bloc.state.step, VasStep.recipient);
        expect(bloc.state.recipientError, isNotNull);
      },
    );

    blocTest<VasBloc, VasState>(
      'a good number loads the options',
      build: build,
      seed: () => ready.copyWith(
        step: VasStep.recipient,
        provider: vodacom,
        recipient: '0825550142',
      ),
      act: (bloc) => bloc.add(const VasEvent.recipientSubmitted()),
      verify: (bloc) {
        expect(bloc.state.step, VasStep.option);
        expect(bloc.state.options, [airtimeOption]);
      },
    );

    blocTest<VasBloc, VasState>(
      'reports an options failure',
      setUp: () => when(
        () => options(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      seed: () => ready.copyWith(
        step: VasStep.recipient,
        provider: vodacom,
        recipient: '0825550142',
      ),
      act: (bloc) => bloc.add(const VasEvent.recipientSubmitted()),
      verify: (bloc) {
        expect(bloc.state.loadStatus, ViewStatus.failure);
        expect(bloc.state.failure, const ServerFailure());
      },
    );

    blocTest<VasBloc, VasState>(
      'choosing an option opens the review',
      build: build,
      seed: () => ready.copyWith(step: VasStep.option),
      act: (bloc) => bloc.add(const VasEvent.optionSelected(airtimeOption)),
      verify: (bloc) => expect(bloc.state.step, VasStep.review),
    );

    blocTest<VasBloc, VasState>(
      'confirm buys and shows the receipt',
      setUp: () => when(
        () => purchase(any()),
      ).thenAnswer((_) async => right(airtimeReceipt)),
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc.add(const VasEvent.confirmed()),
      expect: () => [
        reviewing.copyWith(step: VasStep.processing),
        reviewing.copyWith(step: VasStep.success, receipt: airtimeReceipt),
      ],
      verify: (_) => verify(() => purchase(airtimePurchase)).called(1),
    );

    blocTest<VasBloc, VasState>(
      'confirm shows failures',
      setUp: () => when(
        () => purchase(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc.add(const VasEvent.confirmed()),
      verify: (bloc) => expect(bloc.state.step, VasStep.failure),
    );

    blocTest<VasBloc, VasState>(
      'confirm does nothing when details are missing',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const VasEvent.confirmed()),
      expect: () => <VasState>[],
    );

    blocTest<VasBloc, VasState>(
      'steps back through the flow',
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc
        ..add(const VasEvent.stepBack())
        ..add(const VasEvent.stepBack())
        ..add(const VasEvent.stepBack()),
      verify: (bloc) => expect(bloc.state.step, VasStep.provider),
    );
  });
}
