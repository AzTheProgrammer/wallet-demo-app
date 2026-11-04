import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';

abstract class RewardsRepository {
  Future<Either<Failure, RewardsSummary>> getSummary();

  Future<Either<Failure, List<RewardOffer>>> getOffers();

  Future<Either<Failure, Redemption>> redeem(RewardOffer offer);
}
