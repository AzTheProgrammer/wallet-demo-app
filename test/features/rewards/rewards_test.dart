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
import 'package:wallet_app/features/rewards/data/datasources/rewards_remote_data_source.dart';
import 'package:wallet_app/features/rewards/data/models/rewards_models.dart';
import 'package:wallet_app/features/rewards/data/repositories/rewards_repository_impl.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/rewards/domain/usecases/rewards_usecases.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements RewardsRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(airtimeOffer);
  });

  group('RewardsSummary', () {
    test('finds current and next tier', () {
      expect(rewardsSummary.currentTier.name, 'Silver');
      expect(rewardsSummary.nextTier?.name, 'Gold');
      expect(rewardsSummary.progress, closeTo(0.748, 0.001));
    });

    test('tops out at the last tier', () {
      final top = rewardsSummary.withPoints(20000);
      expect(top.nextTier, isNull);
      expect(top.progress, 1);
    });
  });

  group('use cases', () {
    late MockRewardsRepository repository;

    setUp(() => repository = MockRewardsRepository());

    test('GetRewardsSummary', () async {
      when(
        () => repository.getSummary(),
      ).thenAnswer((_) async => right(rewardsSummary));
      expect(
        await GetRewardsSummary(repository)(const NoParams()),
        right<Failure, RewardsSummary>(rewardsSummary),
      );
    });

    test('GetRewardOffers', () async {
      when(
        () => repository.getOffers(),
      ).thenAnswer((_) async => right(const [airtimeOffer]));
      final result = await GetRewardOffers(repository)(const NoParams());
      expect(result.getOrElse((_) => []), [airtimeOffer]);
    });

    test('RedeemReward', () async {
      when(
        () => repository.redeem(airtimeOffer),
      ).thenAnswer((_) async => right(redemption));
      expect(
        await RedeemReward(repository)(airtimeOffer),
        right<Failure, Redemption>(redemption),
      );
    });
  });

  group('repository', () {
    late MockRemote remote;
    late RewardsRepositoryImpl repository;

    setUp(() {
      remote = MockRemote();
      repository = RewardsRepositoryImpl(remote);
    });

    test('maps the summary', () async {
      when(() => remote.getSummary()).thenAnswer(
        (_) async => const RewardsSummaryModel(
          points: 12480,
          tiers: [
            RewardTierModel(name: 'Bronze', minPoints: 0),
            RewardTierModel(name: 'Silver', minPoints: 5000),
            RewardTierModel(name: 'Gold', minPoints: 15000),
          ],
        ),
      );
      expect(
        await repository.getSummary(),
        right<Failure, RewardsSummary>(rewardsSummary),
      );
    });

    test('maps offers', () async {
      when(() => remote.getOffers()).thenAnswer(
        (_) async => const [
          RewardOfferModel(
            id: 'off-1',
            title: 'R20 airtime',
            description: 'Any network',
            kind: RewardKind.airtime,
            cost: 800,
          ),
        ],
      );
      final result = await repository.getOffers();
      expect(result.getOrElse((_) => []), [airtimeOffer]);
    });

    test('maps a redemption', () async {
      when(() => remote.redeem(any())).thenAnswer(
        (_) async => const RedemptionModel(
          code: 'WLT-123456',
          offerTitle: 'R20 airtime',
          pointsRemaining: 11680,
        ),
      );
      expect(
        await repository.redeem(airtimeOffer),
        right<Failure, Redemption>(redemption),
      );
    });

    test('maps too few points', () async {
      when(
        () => remote.redeem(any()),
      ).thenThrow(const InsufficientPointsException());
      expect(
        await repository.redeem(fuelOffer),
        left<Failure, Redemption>(const InsufficientPointsFailure()),
      );
    });
  });

  group('mock data source', () {
    late MockRewardsDataSource source;

    setUp(() {
      final fixtures = MockFixtureLoader();
      when(() => fixtures.load('rewards')).thenAnswer(
        (_) async => <String, dynamic>{
          'points': 1000,
          'tiers': [
            {'name': 'Bronze', 'min_points': 0},
          ],
        },
      );
      when(() => fixtures.load('reward_offers')).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'off-1',
            'title': 'R20',
            'description': 'Any',
            'kind': 'airtime',
            'cost': 800,
          },
        ],
      );
      final config = DemoConfig()
        ..failureRate = 0
        ..minLatency = Duration.zero
        ..maxLatency = Duration.zero;
      final clock = MockClock();
      when(clock.now).thenReturn(fixedNow);
      source = MockRewardsDataSource(MockServer(config, fixtures, clock));
    });

    test('reads summary and offers', () async {
      expect((await source.getSummary()).points, 1000);
      expect((await source.getOffers()).single.cost, 800);
    });

    test('redeeming spends points', () async {
      final result = await source.redeem(airtimeOffer);
      expect(result.pointsRemaining, 200);
      expect((await source.getSummary()).points, 200);
    });

    test('refuses when points are short', () {
      expect(
        () => source.redeem(fuelOffer),
        throwsA(isA<InsufficientPointsException>()),
      );
    });
  });

  group('RewardsCubit', () {
    late MockGetRewardsSummary summary;
    late MockGetRewardOffers offers;
    late MockRedeemReward redeem;

    setUp(() {
      summary = MockGetRewardsSummary();
      offers = MockGetRewardOffers();
      redeem = MockRedeemReward();
      when(() => summary(any())).thenAnswer((_) async => right(rewardsSummary));
      when(
        () => offers(any()),
      ).thenAnswer((_) async => right(const [airtimeOffer]));
    });

    RewardsCubit build() => RewardsCubit(summary, offers, redeem);

    const loaded = RewardsState(
      status: ViewStatus.success,
      summary: rewardsSummary,
      offers: [airtimeOffer],
    );

    blocTest<RewardsCubit, RewardsState>(
      'loads',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const RewardsState(status: ViewStatus.loading), loaded],
    );

    blocTest<RewardsCubit, RewardsState>(
      'reports load failures',
      setUp: () => when(
        () => offers(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.failure, const OfflineFailure()),
    );

    blocTest<RewardsCubit, RewardsState>(
      'redeems and updates the balance',
      setUp: () =>
          when(() => redeem(any())).thenAnswer((_) async => right(redemption)),
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.redeem(airtimeOffer),
      expect: () => [
        loaded.copyWith(redeemingId: airtimeOffer.id),
        loaded.copyWith(
          redemption: redemption,
          summary: rewardsSummary.withPoints(11680),
        ),
      ],
    );

    blocTest<RewardsCubit, RewardsState>(
      'reports redeem failures',
      setUp: () => when(
        () => redeem(any()),
      ).thenAnswer((_) async => left(const InsufficientPointsFailure())),
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.redeem(fuelOffer),
      expect: () => [
        loaded.copyWith(redeemingId: fuelOffer.id),
        loaded.copyWith(redeemFailure: const InsufficientPointsFailure()),
      ],
    );
  });
}
