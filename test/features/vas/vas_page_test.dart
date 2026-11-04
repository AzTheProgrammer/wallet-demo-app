import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';
import 'package:wallet_app/features/vas/presentation/pages/vas_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockVasBloc bloc;

  setUpAll(() => registerFallbackValue(const VasEvent.recipientSubmitted()));

  setUp(() => bloc = MockVasBloc());

  const ready = VasState(
    loadStatus: ViewStatus.success,
    providers: [vodacom],
    account: mainAccount,
  );

  Future<void> pump(WidgetTester tester, VasState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpRouted(
      BlocProvider<VasBloc>.value(value: bloc, child: const VasPage()),
    );
  }

  group('provider step', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      await pump(tester, const VasState(loadStatus: ViewStatus.loading));
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('retries a failure', (tester) async {
      await pump(
        tester,
        const VasState(
          loadStatus: ViewStatus.failure,
          failure: OfflineFailure(),
          kind: VasKind.data,
        ),
      );
      expect(find.text('Buy data'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const VasEvent.started(VasKind.data))).called(1);
    });

    testWidgets('has an empty state', (tester) async {
      await pump(tester, ready.copyWith(providers: const []));
      expect(find.text('No providers'), findsOneWidget);
    });

    testWidgets('picks a provider', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.text('Vodacom'));
      verify(
        () => bloc.add(const VasEvent.providerSelected(vodacom)),
      ).called(1);
    });
  });

  group('recipient step', () {
    testWidgets('sends edits and submits', (tester) async {
      await pump(tester, ready.copyWith(step: VasStep.recipient));
      await tester.enterText(find.byType(TextFormField), '0825550142');
      await tester.tap(find.text('Continue'));
      verify(
        () => bloc.add(const VasEvent.recipientChanged('0825550142')),
      ).called(1);
      verify(() => bloc.add(const VasEvent.recipientSubmitted())).called(1);
    });

    testWidgets('asks for a meter on electricity', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          step: VasStep.recipient,
          kind: VasKind.electricity,
          recipientError: 'Meter numbers have 11 digits',
        ),
      );
      expect(find.text('Which meter?'), findsOneWidget);
      expect(find.text('Meter numbers have 11 digits'), findsOneWidget);
    });

    testWidgets('back returns to the provider list', (tester) async {
      await pump(tester, ready.copyWith(step: VasStep.recipient));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      verify(() => bloc.add(const VasEvent.stepBack())).called(1);
    });
  });

  group('option step', () {
    testWidgets('picks an option', (tester) async {
      await pump(
        tester,
        ready.copyWith(step: VasStep.option, options: const [airtimeOption]),
      );
      await tester.tap(find.text('R29 airtime'));
      verify(
        () => bloc.add(const VasEvent.optionSelected(airtimeOption)),
      ).called(1);
    });

    testWidgets('has an empty state', (tester) async {
      await pump(tester, ready.copyWith(step: VasStep.option));
      expect(find.text('Nothing to buy'), findsOneWidget);
    });

    testWidgets('retries a failure', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          step: VasStep.option,
          loadStatus: ViewStatus.failure,
          failure: const ServerFailure(),
        ),
      );
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const VasEvent.recipientSubmitted())).called(1);
    });
  });

  final reviewing = ready.copyWith(
    provider: vodacom,
    option: airtimeOption,
    recipient: '0825550142',
  );

  testWidgets('review shows the details', (tester) async {
    await pump(tester, reviewing.copyWith(step: VasStep.review));
    expect(find.text('0825550142'), findsOneWidget);
    expect(find.text('Approve and buy'), findsOneWidget);
  });

  testWidgets('processing shows a skeleton', (tester) async {
    await pump(tester, reviewing.copyWith(step: VasStep.processing));
    expect(find.byType(SkeletonList), findsOneWidget);
  });

  testWidgets('failure retries or cancels', (tester) async {
    await pump(
      tester,
      reviewing.copyWith(
        step: VasStep.failure,
        failure: const OfflineFailure(),
      ),
    );
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const VasEvent.stepBack())).called(1);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('route:/home'), findsOneWidget);
  });

  testWidgets('airtime receipt has no token', (tester) async {
    await pump(
      tester,
      reviewing.copyWith(step: VasStep.success, receipt: airtimeReceipt),
    );
    expect(find.text('R29 airtime purchased'), findsOneWidget);
    expect(find.text('Electricity token'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('route:/home'), findsOneWidget);
  });

  testWidgets('electricity receipt shows the token and units', (tester) async {
    await pump(
      tester,
      reviewing.copyWith(
        kind: VasKind.electricity,
        provider: cityPower,
        option: electricityOption,
        recipient: '12345678901',
        step: VasStep.success,
        receipt: electricityReceipt,
      ),
    );
    expect(find.text('Electricity token'), findsOneWidget);
    expect(find.text(groupToken(electricityReceipt.token!)), findsOneWidget);
    expect(find.text('31.3 kWh'), findsOneWidget);
  });
}
