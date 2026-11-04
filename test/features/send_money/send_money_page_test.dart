import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/send_money/presentation/pages/send_money_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockSendMoneyBloc bloc;

  setUpAll(() => registerFallbackValue(const SendMoneyEvent.started()));

  setUp(() => bloc = MockSendMoneyBloc());

  const ready = SendMoneyState(
    loadStatus: ViewStatus.success,
    beneficiaries: [sipho],
    accounts: [mainAccount, savingsAccount],
    account: mainAccount,
  );

  final filled = ready.copyWith(
    beneficiary: sipho,
    amountText: '150',
    reference: 'Lunch',
  );

  Future<void> pump(WidgetTester tester, SendMoneyState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpRouted(
      BlocProvider<SendMoneyBloc>.value(
        value: bloc,
        child: const SendMoneyPage(),
      ),
    );
  }

  group('recipient step', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      await pump(
        tester,
        const SendMoneyState(loadStatus: ViewStatus.loading),
      );
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('retries a load failure', (tester) async {
      await pump(
        tester,
        const SendMoneyState(
          loadStatus: ViewStatus.failure,
          failure: OfflineFailure(),
        ),
      );
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const SendMoneyEvent.started())).called(1);
    });

    testWidgets('has an empty state', (tester) async {
      await pump(tester, ready.copyWith(beneficiaries: const []));
      expect(find.text('No saved people'), findsOneWidget);
    });

    testWidgets('picks a saved person', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.text('Sipho Dlamini'));
      verify(
        () => bloc.add(const SendMoneyEvent.beneficiarySelected(sipho)),
      ).called(1);
    });

    testWidgets('shows an add failure', (tester) async {
      await pump(tester, ready.copyWith(failure: const ServerFailure()));
      expect(find.text(const ServerFailure().message), findsOneWidget);
    });

    testWidgets('validates and adds a new person', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.text('Add someone new'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and continue'));
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter an account number'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), newPerson.name);
      await tester.enterText(fields.at(1), newPerson.bank);
      await tester.enterText(fields.at(2), newPerson.accountNumber);
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(const SendMoneyEvent.beneficiaryAdded(newPerson)),
      ).called(1);
    });
  });

  group('amount step', () {
    final state = ready.copyWith(
      step: SendMoneyStep.amount,
      beneficiary: sipho,
    );

    testWidgets('sends edits to the bloc', (tester) async {
      await pump(tester, state);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '150');
      await tester.enterText(fields.at(1), 'Lunch');
      verify(
        () => bloc.add(const SendMoneyEvent.amountChanged('150')),
      ).called(1);
      verify(
        () => bloc.add(const SendMoneyEvent.referenceChanged('Lunch')),
      ).called(1);
    });

    testWidgets('shows validation errors', (tester) async {
      await pump(
        tester,
        state.copyWith(amountError: 'Enter an amount', referenceError: 'Ref'),
      );
      expect(find.text('Enter an amount'), findsOneWidget);
      expect(find.text('Ref'), findsOneWidget);
    });

    testWidgets('switches account and asks for review', (tester) async {
      await pump(tester, state);
      await tester.tap(find.text('Savings pocket'));
      await tester.tap(find.text('Review payment'));
      verify(
        () => bloc.add(const SendMoneyEvent.accountSelected(savingsAccount)),
      ).called(1);
      verify(() => bloc.add(const SendMoneyEvent.reviewRequested())).called(1);
    });

    testWidgets('back returns to the previous step', (tester) async {
      await pump(tester, state);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      verify(() => bloc.add(const SendMoneyEvent.stepBack())).called(1);
    });
  });

  testWidgets('review shows the details', (tester) async {
    await pump(tester, filled.copyWith(step: SendMoneyStep.review));
    expect(find.text('Check the details'), findsOneWidget);
    expect(find.text('Capitec'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Approve and send'), findsOneWidget);
  });

  testWidgets('processing shows a skeleton and hides back', (tester) async {
    await pump(tester, filled.copyWith(step: SendMoneyStep.processing));
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('failure retries or cancels', (tester) async {
    await pump(
      tester,
      filled.copyWith(
        step: SendMoneyStep.failure,
        failure: const InsufficientFundsFailure(),
      ),
    );
    expect(find.text(const InsufficientFundsFailure().message), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const SendMoneyEvent.stepBack())).called(1);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('route:/home'), findsOneWidget);
  });

  testWidgets('success shows a receipt', (tester) async {
    await pump(
      tester,
      filled.copyWith(step: SendMoneyStep.success, receipt: sendReceipt),
    );
    expect(find.text('Sent to Sipho Dlamini'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('route:/home'), findsOneWidget);
  });
}
