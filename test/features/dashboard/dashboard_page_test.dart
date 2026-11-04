import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/quick_actions.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockDashboardCubit cubit;

  setUp(() => cubit = MockDashboardCubit());

  final loaded = DashboardState(
    status: ViewStatus.success,
    accounts: const [mainAccount, savingsAccount],
    recent: [payment, salary],
    firstName: 'Thandi',
  );

  Future<void> pump(WidgetTester tester, {double textScale = 1}) =>
      tester.pumpRouted(
        BlocProvider<DashboardCubit>.value(
          value: cubit,
          child: const DashboardPage(),
        ),
        textScale: textScale,
      );

  testWidgets('shows a skeleton while loading', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const DashboardState(status: ViewStatus.loading));
    await pump(tester);
    expect(find.byType(DashboardSkeleton), findsOneWidget);
  });

  testWidgets('shows balances and activity', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Hi Thandi'), findsOneWidget);
    expect(find.byType(BalanceCard), findsNWidgets(2));
    expect(find.text(mainAccount.balance.format()), findsOneWidget);
    expect(find.text('Woolworths Food'), findsOneWidget);
  });

  testWidgets('shows a neutral greeting and empty activity', (tester) async {
    when(() => cubit.state).thenReturn(
      const DashboardState(
        status: ViewStatus.success,
        accounts: [mainAccount],
      ),
    );
    await pump(tester);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('No activity yet'), findsOneWidget);
  });

  testWidgets('offers a retry on failure', (tester) async {
    when(() => cubit.state).thenReturn(
      const DashboardState(
        status: ViewStatus.failure,
        failure: OfflineFailure(),
      ),
    );
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester);
    expect(find.text('No connection'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => cubit.load()).called(1);
  });

  testWidgets('shows a snackbar when a refresh fails', (tester) async {
    whenListen(
      cubit,
      Stream.value(loaded.copyWith(refreshFailure: const OfflineFailure())),
      initialState: loaded,
    );
    await pump(tester);
    await tester.pump();
    expect(find.text(const OfflineFailure().message), findsOneWidget);
  });

  testWidgets('pull to refresh calls the cubit', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    when(() => cubit.refresh()).thenAnswer((_) async {});
    await pump(tester);
    await tester.fling(find.text('Hi Thandi'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('quick actions open their flows', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await pump(tester);
    expect(find.byType(QuickActions), findsOneWidget);
    await tester.tap(find.text('Electricity'));
    await tester.pumpAndSettle();
    expect(find.text('route:/vas/electricity'), findsOneWidget);
  });

  testWidgets('tapping activity opens its detail', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await pump(tester);
    await tester.tap(find.text('Woolworths Food'));
    await tester.pumpAndSettle();
    expect(find.text('route:/activity/txn-1?from=home'), findsOneWidget);
  });

  testWidgets('fits at 1.5x text', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await pump(tester, textScale: 1.5);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
