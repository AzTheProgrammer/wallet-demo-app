import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/mock/mock_ledger.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/send_money/data/datasources/send_money_remote_data_source.dart';
import 'package:wallet_app/features/send_money/data/models/beneficiary_model.dart';
import 'package:wallet_app/features/send_money/data/repositories/send_money_repository_impl.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/send_money/domain/usecases/send_money_usecases.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements SendMoneyRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(newPerson);
    registerFallbackValue(sendRequest);
  });

  group('use cases', () {
    late MockSendMoneyRepository repository;

    setUp(() => repository = MockSendMoneyRepository());

    test('GetBeneficiaries passes through', () async {
      when(
        () => repository.getBeneficiaries(),
      ).thenAnswer((_) async => right(const [sipho]));
      final result = await GetBeneficiaries(repository)(const NoParams());
      expect(result.getOrElse((_) => []), [sipho]);
    });

    test('AddBeneficiary saves valid details', () async {
      when(
        () => repository.addBeneficiary(newPerson),
      ).thenAnswer((_) async => right(sipho));
      expect(
        await AddBeneficiary(repository)(newPerson),
        right<Failure, Beneficiary>(sipho),
      );
    });

    test('AddBeneficiary rejects bad details', () async {
      final result = await AddBeneficiary(repository)(
        const NewBeneficiary(name: 'A', bank: 'B', accountNumber: '1'),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.addBeneficiary(any()));
    });

    test('SendMoney sends a positive amount', () async {
      when(
        () => repository.send(sendRequest),
      ).thenAnswer((_) async => right(sendReceipt));
      expect(
        await SendMoney(repository)(sendRequest),
        right<Failure, SendMoneyReceipt>(sendReceipt),
      );
    });

    test('SendMoney rejects zero', () async {
      final result = await SendMoney(repository)(
        const SendMoneyRequest(
          fromAccountId: 'a',
          beneficiary: sipho,
          amount: Money.zero,
          reference: 'x',
        ),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('repository', () {
    late MockRemote remote;
    late SendMoneyRepositoryImpl repository;

    const model = BeneficiaryModel(
      id: 'ben-1',
      name: 'Sipho Dlamini',
      bank: 'Capitec',
      accountNumber: '1450028813',
    );

    setUp(() {
      remote = MockRemote();
      repository = SendMoneyRepositoryImpl(remote);
    });

    test('maps beneficiaries', () async {
      when(() => remote.getBeneficiaries()).thenAnswer((_) async => [model]);
      final result = await repository.getBeneficiaries();
      expect(result.getOrElse((_) => []), [sipho]);
    });

    test('maps an added beneficiary', () async {
      when(() => remote.addBeneficiary(any())).thenAnswer((_) async => model);
      expect(
        await repository.addBeneficiary(newPerson),
        right<Failure, Beneficiary>(sipho),
      );
    });

    test('maps a receipt', () async {
      when(() => remote.send(any())).thenAnswer(
        (_) async => SendReceiptModel(
          transactionId: 'txn-9',
          reference: 'Lunch',
          sentAt: fixedNow,
        ),
      );
      expect(
        await repository.send(sendRequest),
        right<Failure, SendMoneyReceipt>(sendReceipt),
      );
    });

    test('maps insufficient funds', () async {
      when(
        () => remote.send(any()),
      ).thenThrow(const InsufficientFundsException());
      expect(
        await repository.send(sendRequest),
        left<Failure, SendMoneyReceipt>(const InsufficientFundsFailure()),
      );
    });
  });

  group('mock data source', () {
    late MockSendMoneyDataSource source;
    late MockServer server;

    setUp(() {
      final fixtures = MockFixtureLoader();
      final clock = MockClock();
      when(clock.now).thenReturn(fixedNow);
      when(() => fixtures.load('beneficiaries')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'ben-1',
            'name': 'Sipho',
            'bank': 'Capitec',
            'account_number': '1450028813',
          },
        ],
      );
      when(() => fixtures.load('accounts')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'acc-main',
            'name': 'Everyday',
            'balance_cents': 20000,
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
      server = MockServer(config, fixtures, clock);
      source = MockSendMoneyDataSource(server, MockLedger(server));
    });

    test('lists and adds beneficiaries', () async {
      await source.addBeneficiary(newPerson);
      final people = await source.getBeneficiaries();
      expect(people.map((person) => person.name), ['Anele Naidoo', 'Sipho']);
    });

    test('sending debits the account and records a transaction', () async {
      final receipt = await source.send(sendRequest);
      final accounts = await server.table('accounts');
      final ledger = await server.table('transactions');
      expect(accounts.single['balance_cents'], 5000);
      expect(ledger.single['id'], receipt.transactionId);
      expect(ledger.single['title'], sipho.name);
    });
  });

  group('SendMoneyBloc', () {
    late MockGetBeneficiaries getBeneficiaries;
    late MockGetAccounts getAccounts;
    late MockAddBeneficiary addBeneficiary;
    late MockSendMoney sendMoney;

    setUp(() {
      getBeneficiaries = MockGetBeneficiaries();
      getAccounts = MockGetAccounts();
      addBeneficiary = MockAddBeneficiary();
      sendMoney = MockSendMoney();
      when(
        () => getBeneficiaries(any()),
      ).thenAnswer((_) async => right(const [sipho]));
      when(
        () => getAccounts(any()),
      ).thenAnswer(
        (_) async => right(const [mainAccount, savingsAccount]),
      );
    });

    SendMoneyBloc build() =>
        SendMoneyBloc(getBeneficiaries, getAccounts, addBeneficiary, sendMoney);

    const ready = SendMoneyState(
      loadStatus: ViewStatus.success,
      beneficiaries: [sipho],
      accounts: [mainAccount, savingsAccount],
      account: mainAccount,
    );

    final reviewing = ready.copyWith(
      step: SendMoneyStep.review,
      beneficiary: sipho,
      amountText: '150',
      reference: 'Lunch',
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'loads people and accounts',
      build: build,
      act: (bloc) => bloc.add(const SendMoneyEvent.started()),
      expect: () => [
        const SendMoneyState(loadStatus: ViewStatus.loading),
        ready,
      ],
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'reports a load failure',
      setUp: () => when(
        () => getBeneficiaries(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      act: (bloc) => bloc.add(const SendMoneyEvent.started()),
      expect: () => [
        const SendMoneyState(loadStatus: ViewStatus.loading),
        const SendMoneyState(
          loadStatus: ViewStatus.failure,
          failure: OfflineFailure(),
        ),
      ],
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'picking someone moves to the amount',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const SendMoneyEvent.beneficiarySelected(sipho)),
      expect: () => [
        ready.copyWith(step: SendMoneyStep.amount, beneficiary: sipho),
      ],
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'adding someone selects them',
      setUp: () => when(
        () => addBeneficiary(any()),
      ).thenAnswer((_) async => right(sipho)),
      build: build,
      seed: () => ready.copyWith(beneficiaries: const []),
      act: (bloc) => bloc.add(const SendMoneyEvent.beneficiaryAdded(newPerson)),
      verify: (bloc) {
        expect(bloc.state.step, SendMoneyStep.amount);
        expect(bloc.state.beneficiaries, [sipho]);
      },
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'stays put when adding fails',
      setUp: () => when(
        () => addBeneficiary(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const SendMoneyEvent.beneficiaryAdded(newPerson)),
      verify: (bloc) {
        expect(bloc.state.step, SendMoneyStep.recipient);
        expect(bloc.state.failure, const ServerFailure());
        expect(bloc.state.isAddingBeneficiary, isFalse);
      },
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'field edits clear their errors',
      build: build,
      seed: () => ready.copyWith(amountError: 'x', referenceError: 'y'),
      act: (bloc) => bloc
        ..add(const SendMoneyEvent.amountChanged('10'))
        ..add(const SendMoneyEvent.referenceChanged('Rent'))
        ..add(const SendMoneyEvent.accountSelected(savingsAccount)),
      verify: (bloc) {
        expect(bloc.state.amountError, isNull);
        expect(bloc.state.referenceError, isNull);
        expect(bloc.state.amount, const Money(1000));
        expect(bloc.state.account, savingsAccount);
      },
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'review validates the form',
      build: build,
      seed: () => ready.copyWith(step: SendMoneyStep.amount),
      act: (bloc) => bloc.add(const SendMoneyEvent.reviewRequested()),
      verify: (bloc) {
        expect(bloc.state.step, SendMoneyStep.amount);
        expect(bloc.state.amountError, isNotNull);
        expect(bloc.state.referenceError, isNotNull);
      },
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'review blocks more than the balance',
      build: build,
      seed: () => ready.copyWith(
        step: SendMoneyStep.amount,
        amountText: '999999',
        reference: 'Too much',
      ),
      act: (bloc) => bloc.add(const SendMoneyEvent.reviewRequested()),
      verify: (bloc) => expect(bloc.state.amountError, isNotNull),
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'review opens for a valid form',
      build: build,
      seed: () => ready.copyWith(
        step: SendMoneyStep.amount,
        amountText: '150',
        reference: 'Lunch',
      ),
      act: (bloc) => bloc.add(const SendMoneyEvent.reviewRequested()),
      verify: (bloc) => expect(bloc.state.step, SendMoneyStep.review),
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'confirm sends and shows the receipt',
      setUp: () => when(
        () => sendMoney(any()),
      ).thenAnswer((_) async => right(sendReceipt)),
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc.add(const SendMoneyEvent.confirmed()),
      expect: () => [
        reviewing.copyWith(step: SendMoneyStep.processing),
        reviewing.copyWith(step: SendMoneyStep.success, receipt: sendReceipt),
      ],
      verify: (_) => verify(() => sendMoney(sendRequest)).called(1),
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'confirm shows failures',
      setUp: () => when(
        () => sendMoney(any()),
      ).thenAnswer((_) async => left(const InsufficientFundsFailure())),
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc.add(const SendMoneyEvent.confirmed()),
      expect: () => [
        reviewing.copyWith(step: SendMoneyStep.processing),
        reviewing.copyWith(
          step: SendMoneyStep.failure,
          failure: const InsufficientFundsFailure(),
        ),
      ],
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'confirm does nothing without a recipient',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const SendMoneyEvent.confirmed()),
      expect: () => <SendMoneyState>[],
    );

    blocTest<SendMoneyBloc, SendMoneyState>(
      'steps back through the flow',
      build: build,
      seed: () => reviewing,
      act: (bloc) => bloc
        ..add(const SendMoneyEvent.stepBack())
        ..add(const SendMoneyEvent.stepBack()),
      expect: () => [
        reviewing.copyWith(step: SendMoneyStep.amount),
        reviewing.copyWith(step: SendMoneyStep.recipient),
      ],
    );
  });

  test('Beneficiary initials', () {
    expect(sipho.initials, 'SD');
  });
}
