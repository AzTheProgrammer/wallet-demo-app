import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/usecases/get_accounts.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/domain/usecases/vas_usecases.dart';

part 'vas_bloc.freezed.dart';
part 'vas_event.dart';
part 'vas_state.dart';

@injectable
class VasBloc extends Bloc<VasEvent, VasState> {
  VasBloc(
    this._getProviders,
    this._getOptions,
    this._getAccounts,
    this._purchase,
  ) : super(const VasState()) {
    on<VasStarted>(_onStarted);
    on<VasProviderSelected>(
      (event, emit) => emit(
        state.copyWith(provider: event.provider, step: VasStep.recipient),
      ),
    );
    on<VasRecipientChanged>(
      (event, emit) => emit(
        state.copyWith(recipient: event.recipient, recipientError: null),
      ),
    );
    on<VasRecipientSubmitted>(_onRecipientSubmitted);
    on<VasOptionSelected>(
      (event, emit) =>
          emit(state.copyWith(option: event.option, step: VasStep.review)),
    );
    on<VasConfirmed>(_onConfirmed);
    on<VasStepBack>(_onStepBack);
  }

  final GetVasProviders _getProviders;
  final GetVasOptions _getOptions;
  final GetAccounts _getAccounts;
  final PurchaseVas _purchase;

  Future<void> _onStarted(VasStarted event, Emitter<VasState> emit) async {
    emit(
      state.copyWith(
        kind: event.kind,
        loadStatus: ViewStatus.loading,
        failure: null,
      ),
    );
    final providers = await _getProviders(event.kind);
    final accounts = await _getAccounts(const NoParams());
    final failure =
        providers.getLeft().toNullable() ?? accounts.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(loadStatus: ViewStatus.failure, failure: failure));
      return;
    }
    final loaded = accounts.getOrElse((_) => const []);
    emit(
      state.copyWith(
        loadStatus: ViewStatus.success,
        providers: providers.getOrElse((_) => const []),
        account: loaded.isEmpty ? null : loaded.first,
      ),
    );
  }

  Future<void> _onRecipientSubmitted(
    VasRecipientSubmitted event,
    Emitter<VasState> emit,
  ) async {
    final error = PurchaseVas.recipientError(state.kind, state.recipient);
    final provider = state.provider;
    if (error != null || provider == null) {
      emit(state.copyWith(recipientError: error));
      return;
    }
    emit(
      state.copyWith(
        step: VasStep.option,
        loadStatus: ViewStatus.loading,
        failure: null,
      ),
    );
    final options = await _getOptions(
      VasOptionsParams(kind: state.kind, providerId: provider.id),
    );
    options.match(
      (failure) => emit(
        state.copyWith(loadStatus: ViewStatus.failure, failure: failure),
      ),
      (items) => emit(
        state.copyWith(loadStatus: ViewStatus.success, options: items),
      ),
    );
  }

  Future<void> _onConfirmed(VasConfirmed event, Emitter<VasState> emit) async {
    final provider = state.provider;
    final option = state.option;
    final account = state.account;
    if (provider == null || option == null || account == null) return;
    emit(state.copyWith(step: VasStep.processing, failure: null));
    final result = await _purchase(
      VasPurchase(
        kind: state.kind,
        provider: provider,
        option: option,
        recipient: state.recipient.replaceAll(' ', ''),
        accountId: account.id,
      ),
    );
    result.match(
      (failure) =>
          emit(state.copyWith(step: VasStep.failure, failure: failure)),
      (receipt) =>
          emit(state.copyWith(step: VasStep.success, receipt: receipt)),
    );
  }

  void _onStepBack(VasStepBack event, Emitter<VasState> emit) {
    final previous = switch (state.step) {
      VasStep.recipient => VasStep.provider,
      VasStep.option => VasStep.recipient,
      VasStep.review || VasStep.failure => VasStep.option,
      _ => state.step,
    };
    emit(
      state.copyWith(
        step: previous,
        failure: null,
        loadStatus: ViewStatus.success,
      ),
    );
  }
}
