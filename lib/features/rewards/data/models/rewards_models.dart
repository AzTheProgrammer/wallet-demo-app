import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';

part 'rewards_models.freezed.dart';
part 'rewards_models.g.dart';

@freezed
abstract class RewardTierModel with _$RewardTierModel {
  const factory RewardTierModel({
    required String name,
    required int minPoints,
  }) = _RewardTierModel;

  factory RewardTierModel.fromJson(Map<String, dynamic> json) =>
      _$RewardTierModelFromJson(json);
}

@freezed
abstract class RewardsSummaryModel with _$RewardsSummaryModel {
  const factory RewardsSummaryModel({
    required int points,
    required List<RewardTierModel> tiers,
  }) = _RewardsSummaryModel;

  const RewardsSummaryModel._();

  factory RewardsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$RewardsSummaryModelFromJson(json);

  RewardsSummary toEntity() => RewardsSummary(
    points: points,
    tiers: tiers
        .map((tier) => RewardTier(name: tier.name, minPoints: tier.minPoints))
        .toList(),
  );
}

@freezed
abstract class RewardOfferModel with _$RewardOfferModel {
  const factory RewardOfferModel({
    required String id,
    required String title,
    required String description,
    required RewardKind kind,
    required int cost,
  }) = _RewardOfferModel;

  const RewardOfferModel._();

  factory RewardOfferModel.fromJson(Map<String, dynamic> json) =>
      _$RewardOfferModelFromJson(json);

  RewardOffer toEntity() => RewardOffer(
    id: id,
    title: title,
    description: description,
    kind: kind,
    cost: cost,
  );
}

@freezed
abstract class RedemptionModel with _$RedemptionModel {
  const factory RedemptionModel({
    required String code,
    required String offerTitle,
    required int pointsRemaining,
  }) = _RedemptionModel;

  const RedemptionModel._();

  factory RedemptionModel.fromJson(Map<String, dynamic> json) =>
      _$RedemptionModelFromJson(json);

  Redemption toEntity() => Redemption(
    code: code,
    offerTitle: offerTitle,
    pointsRemaining: pointsRemaining,
  );
}
