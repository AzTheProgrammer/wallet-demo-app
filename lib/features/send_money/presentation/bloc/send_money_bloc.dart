import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/usecases/get_accounts.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/send_money/domain/usecases/send_money_usecases.dart';

part 'send_money_bloc.freezed.dart';
part 'send_money_event.dart';
part 'send_money_state.dart';

@injectable
class SendMoneyBloc extends Bloc<SendMoneyEvent, SendMoneyState> {
  SendMoneyBloc(
    this._getBeneficiaries,
    this._getAccounts,
    this._addBeneficiary,
    this._sendMoney,
  ) : super(const SendMoneyState()) {
    on<SendMoneyStarted>(_onStarted);
    on<BeneficiarySelected>(_onBeneficiarySelected);
    on<BeneficiaryAdded>(_onBeneficiaryAdded);
    on<AccountSelected>(
      (event, emit) => emit(
        state.copyWith(account: event.account, amountError: null),
      ),
    );
    on<AmountChanged>(
      (event, emit) => emit(
        state.copyWith(amountText: event.amount, amountError: null),
      ),
    );
    on<ReferenceChanged>(
      (event, emit) => emit(
        state.copyWith(reference: event.reference, referenceError: null),
      ),
    );
    on<ReviewRequested>(_onReviewRequested);
    on<SendConfirmed>(_onConfirmed);
    on<SendStepBack>(_onStepBack);
  }

  final GetBeneficiaries _getBeneficiaries;
  final GetAccounts _getAccounts;
  final AddBeneficiary _addBeneficiary;
  final SendMoney _sendMoney;

  Future<void> _onStarted(
    SendMoneyStarted event,
    Emitter<SendMoneyState> emit,
  ) async {
    emit(state.copyWith(loadStatus: ViewStatus.loading, failure: null));
    final beneficiaries = await _getBeneficiaries(const NoParams());
    final accounts = await _getAccounts(const NoParams());
    final failure =
        beneficiaries.getLeft().toNullable() ?? accounts.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(loadStatus: ViewStatus.failure, failure: failure));
      return;
    }
    final loaded = accounts.getOrElse((_) => const []);
    emit(
      state.copyWith(
        loadStatus: ViewStatus.success,
        beneficiaries: beneficiaries.getOrElse((_) => const []),
        accounts: loaded,
        account: loaded.isEmpty ? null : loaded.first,
      ),
    );
  }

  void _onBeneficiarySelected(
    BeneficiarySelected event,
    Emitter<SendMoneyState> emit,
  ) => emit(
    state.copyWith(beneficiary: event.beneficiary, step: SendMoneyStep.amount),
  );

  Future<void> _onBeneficiaryAdded(
    BeneficiaryAdded event,
    Emitter<SendMoneyState> emit,
  ) async {
    emit(state.copyWith(isAddingBeneficiary: true, failure: null));
    final result = await _addBeneficiary(event.details);
    result.match(
      (failure) => emit(
        state.copyWith(isAddingBeneficiary: false, failure: failure),
      ),
      (beneficiary) => emit(
        state.copyWith(
          isAddingBeneficiary: false,
          beneficiaries: [beneficiary, ...state.beneficiaries],
          beneficiary: beneficiary,
          step: SendMoneyStep.amount,
        ),
      ),
    );
  }

  void _onReviewRequested(
    ReviewRequested event,
    Emitter<SendMoneyState> emit,
  ) {
    final available = state.account?.balance ?? Money.zero;
    final amountError = Validators.amount(
      state.amountText,
      available: available,
    );
    final referenceError = Validators.required(state.reference, 'a reference');
    if (amountError != null || referenceError != null) {
      emit(
        state.copyWith(
          amountError: amountError,
          referenceError: referenceError,
        ),
      );
      return;
    }
    emit(state.copyWith(step: SendMoneyStep.review));
  }

  Future<void> _onConfirmed(
    SendConfirmed event,
    Emitter<SendMoneyState> emit,
  ) async {
    final account = state.account;
    final beneficiary = state.beneficiary;
    if (account == null || beneficiary == null) return;
    emit(state.copyWith(step: SendMoneyStep.processing, failure: null));
    final result = await _sendMoney(
      SendMoneyRequest(
        fromAccountId: account.id,
        beneficiary: beneficiary,
        amount: state.amount,
        reference: state.reference.trim(),
      ),
    );
    result.match(
      (failure) => emit(
        state.copyWith(step: SendMoneyStep.failure, failure: failure),
      ),
      (receipt) => emit(
        state.copyWith(step: SendMoneyStep.success, receipt: receipt),
      ),
    );
  }

  void _onStepBack(SendStepBack event, Emitter<SendMoneyState> emit) {
    final previous = switch (state.step) {
      SendMoneyStep.amount => SendMoneyStep.recipient,
      SendMoneyStep.review || SendMoneyStep.failure => SendMoneyStep.amount,
      _ => state.step,
    };
    emit(state.copyWith(step: previous, failure: null));
  }
}
