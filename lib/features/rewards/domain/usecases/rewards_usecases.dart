import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/rewards/domain/repositories/rewards_repository.dart';

@injectable
class GetRewardsSummary implements UseCase<RewardsSummary, NoParams> {
  const GetRewardsSummary(this._repository);

  final RewardsRepository _repository;

  @override
  Future<Either<Failure, RewardsSummary>> call(NoParams params) =>
      _repository.getSummary();
}

@injectable
class GetRewardOffers implements UseCase<List<RewardOffer>, NoParams> {
  const GetRewardOffers(this._repository);

  final RewardsRepository _repository;

  @override
  Future<Either<Failure, List<RewardOffer>>> call(NoParams params) =>
      _repository.getOffers();
}

@injectable
class RedeemReward implements UseCase<Redemption, RewardOffer> {
  const RedeemReward(this._repository);

  final RewardsRepository _repository;

  @override
  Future<Either<Failure, Redemption>> call(RewardOffer offer) =>
      _repository.redeem(offer);
}
