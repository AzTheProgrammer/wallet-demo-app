import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';
import 'package:wallet_app/features/rewards/presentation/pages/rewards_page.dart';
import 'package:wallet_app/features/rewards/presentation/widgets/points_card.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockRewardsCubit cubit;

  setUpAll(() => registerFallbackValue(airtimeOffer));

  setUp(() => cubit = MockRewardsCubit());

  const loaded = RewardsState(
    status: ViewStatus.success,
    summary: rewardsSummary,
    offers: [airtimeOffer, fuelOffer],
  );

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    BlocProvider<RewardsCubit>.value(value: cubit, child: const RewardsPage()),
  );

  testWidgets('shows a skeleton while loading', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const RewardsState(status: ViewStatus.loading));
    await pump(tester);
    expect(find.byType(Skeleton), findsOneWidget);
  });

  testWidgets('retries a failure', (tester) async {
    when(() => cubit.state).thenReturn(
      const RewardsState(status: ViewStatus.failure, failure: OfflineFailure()),
    );
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester);
    await tester.tap(find.text('Try again'));
    verify(() => cubit.load()).called(1);
  });

  testWidgets('shows points, tier and offers', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await pump(tester);
    expect(find.byType(PointsCard), findsOneWidget);
    expect(find.text('Silver member'), findsOneWidget);
    expect(find.textContaining('to Gold'), findsOneWidget);
    expect(find.text('R20 airtime'), findsOneWidget);
    expect(find.text('Not enough'), findsOneWidget);
  });

  testWidgets('celebrates the top tier', (tester) async {
    when(() => cubit.state).thenReturn(
      loaded.copyWith(summary: rewardsSummary.withPoints(16000)),
    );
    await pump(tester);
    expect(find.text('You have reached the top tier'), findsOneWidget);
  });

  testWidgets('has an empty state', (tester) async {
    when(() => cubit.state).thenReturn(loaded.copyWith(offers: const []));
    await pump(tester);
    expect(find.text('No rewards right now'), findsOneWidget);
  });

  testWidgets('redeems an affordable offer only', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    when(() => cubit.redeem(any())).thenAnswer((_) async {});
    await pump(tester);
    await tester.tap(find.text('R20 airtime'));
    await tester.tap(find.text('R500 fuel voucher'));
    verify(() => cubit.redeem(airtimeOffer)).called(1);
    verifyNever(() => cubit.redeem(fuelOffer));
  });

  testWidgets('ignores taps while redeeming', (tester) async {
    when(() => cubit.state).thenReturn(loaded.copyWith(redeemingId: 'off-1'));
    await pump(tester);
    await tester.tap(find.text('R20 airtime'));
    verifyNever(() => cubit.redeem(any()));
  });

  testWidgets('shows the code after redeeming', (tester) async {
    whenListen(
      cubit,
      Stream.value(loaded.copyWith(redemption: redemption)),
      initialState: loaded.copyWith(redeemingId: 'off-1'),
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('WLT-123456'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('WLT-123456'), findsNothing);
  });

  testWidgets('shows redeem failures', (tester) async {
    whenListen(
      cubit,
      Stream.value(
        loaded.copyWith(redeemFailure: const InsufficientPointsFailure()),
      ),
      initialState: loaded.copyWith(redeemingId: 'off-1'),
    );
    await pump(tester);
    await tester.pump();
    expect(
      find.text(const InsufficientPointsFailure().message),
      findsOneWidget,
    );
  });
}
