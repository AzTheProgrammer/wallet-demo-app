import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/rewards/data/models/rewards_models.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';

abstract class RewardsRemoteDataSource {
  Future<RewardsSummaryModel> getSummary();

  Future<List<RewardOfferModel>> getOffers();

  Future<RedemptionModel> redeem(RewardOffer offer);
}

@mockSource
@LazySingleton(as: RewardsRemoteDataSource)
class MockRewardsDataSource implements RewardsRemoteDataSource {
  const MockRewardsDataSource(this._server);

  final MockServer _server;

  @override
  Future<RewardsSummaryModel> getSummary() => _server.respond(() async {
    final row = await _server.document('rewards');
    return RewardsSummaryModel.fromJson(row);
  });

  @override
  Future<List<RewardOfferModel>> getOffers() => _server.respond(() async {
    final rows = await _server.table('reward_offers');
    return rows.map(RewardOfferModel.fromJson).toList();
  });

  @override
  Future<RedemptionModel> redeem(RewardOffer offer) =>
      _server.respond(() async {
        final row = await _server.document('rewards');
        final points = row['points'] as int;
        if (offer.cost > points) throw const InsufficientPointsException();
        row['points'] = points - offer.cost;
        return RedemptionModel(
          code: 'WLT-${_server.random.nextInt(899999) + 100000}',
          offerTitle: offer.title,
          pointsRemaining: points - offer.cost,
        );
      });
}
