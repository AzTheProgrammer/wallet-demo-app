import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/rewards/domain/usecases/rewards_usecases.dart';

part 'rewards_cubit.freezed.dart';

@freezed
abstract class RewardsState with _$RewardsState {
  const factory RewardsState({
    @Default(ViewStatus.initial) ViewStatus status,
    RewardsSummary? summary,
    @Default(<RewardOffer>[]) List<RewardOffer> offers,
    String? redeemingId,
    Redemption? redemption,
    Failure? failure,
    Failure? redeemFailure,
  }) = _RewardsState;
}

@injectable
class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit(this._getSummary, this._getOffers, this._redeem)
    : super(const RewardsState());

  final GetRewardsSummary _getSummary;
  final GetRewardOffers _getOffers;
  final RedeemReward _redeem;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, failure: null));
    final summary = await _getSummary(const NoParams());
    final offers = await _getOffers(const NoParams());
    final failure =
        summary.getLeft().toNullable() ?? offers.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: ViewStatus.failure, failure: failure));
      return;
    }
    emit(
      state.copyWith(
        status: ViewStatus.success,
        summary: summary.toNullable(),
        offers: offers.getOrElse((_) => const []),
      ),
    );
  }

  Future<void> redeem(RewardOffer offer) async {
    emit(
      state.copyWith(
        redeemingId: offer.id,
        redemption: null,
        redeemFailure: null,
      ),
    );
    final result = await _redeem(offer);
    result.match(
      (failure) =>
          emit(state.copyWith(redeemingId: null, redeemFailure: failure)),
      (redemption) => emit(
        state.copyWith(
          redeemingId: null,
          redemption: redemption,
          summary: state.summary?.withPoints(redemption.pointsRemaining),
        ),
      ),
    );
  }
}
