import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/rewards/data/datasources/rewards_remote_data_source.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/rewards/domain/repositories/rewards_repository.dart';

@LazySingleton(as: RewardsRepository)
class RewardsRepositoryImpl implements RewardsRepository {
  const RewardsRepositoryImpl(this._remote);

  final RewardsRemoteDataSource _remote;

  @override
  Future<Either<Failure, RewardsSummary>> getSummary() =>
      guard(() async => (await _remote.getSummary()).toEntity());

  @override
  Future<Either<Failure, List<RewardOffer>>> getOffers() => guard(() async {
    final models = await _remote.getOffers();
    return models.map((model) => model.toEntity()).toList();
  });

  @override
  Future<Either<Failure, Redemption>> redeem(RewardOffer offer) =>
      guard(() async => (await _remote.redeem(offer)).toEntity());
}
