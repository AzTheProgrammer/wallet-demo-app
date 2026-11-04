import 'package:equatable/equatable.dart';

enum RewardKind { airtime, data, voucher }

class RewardTier extends Equatable {
  const RewardTier({required this.name, required this.minPoints});

  final String name;
  final int minPoints;

  @override
  List<Object?> get props => [name, minPoints];
}

class RewardsSummary extends Equatable {
  const RewardsSummary({required this.points, required this.tiers});

  final int points;
  final List<RewardTier> tiers;

  RewardTier get currentTier => tiers.lastWhere(
    (tier) => points >= tier.minPoints,
    orElse: () => tiers.first,
  );

  RewardTier? get nextTier {
    for (final tier in tiers) {
      if (tier.minPoints > points) return tier;
    }
    return null;
  }

  double get progress {
    final next = nextTier;
    if (next == null) return 1;
    final floor = currentTier.minPoints;
    return (points - floor) / (next.minPoints - floor);
  }

  RewardsSummary withPoints(int value) =>
      RewardsSummary(points: value, tiers: tiers);

  @override
  List<Object?> get props => [points, tiers];
}

class RewardOffer extends Equatable {
  const RewardOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.cost,
  });

  final String id;
  final String title;
  final String description;
  final RewardKind kind;
  final int cost;

  @override
  List<Object?> get props => [id, title, description, kind, cost];
}

class Redemption extends Equatable {
  const Redemption({
    required this.code,
    required this.offerTitle,
    required this.pointsRemaining,
  });

  final String code;
  final String offerTitle;
  final int pointsRemaining;

  @override
  List<Object?> get props => [code, offerTitle, pointsRemaining];
}
