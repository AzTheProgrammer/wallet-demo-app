import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/send_money/domain/repositories/send_money_repository.dart';

@injectable
class GetBeneficiaries implements UseCase<List<Beneficiary>, NoParams> {
  const GetBeneficiaries(this._repository);

  final SendMoneyRepository _repository;

  @override
  Future<Either<Failure, List<Beneficiary>>> call(NoParams params) =>
      _repository.getBeneficiaries();
}

@injectable
class AddBeneficiary implements UseCase<Beneficiary, NewBeneficiary> {
  const AddBeneficiary(this._repository);

  final SendMoneyRepository _repository;

  @override
  Future<Either<Failure, Beneficiary>> call(NewBeneficiary params) async {
    final problem =
        Validators.required(params.name, 'a name') ??
        Validators.required(params.bank, 'a bank') ??
        Validators.accountNumber(params.accountNumber);
    if (problem != null) return left(ValidationFailure(problem));
    return _repository.addBeneficiary(params);
  }
}

@injectable
class SendMoney implements UseCase<SendMoneyReceipt, SendMoneyRequest> {
  const SendMoney(this._repository);

  final SendMoneyRepository _repository;

  @override
  Future<Either<Failure, SendMoneyReceipt>> call(
    SendMoneyRequest params,
  ) async {
    if (!params.amount.isPositive) {
      return left(const ValidationFailure('Enter an amount above zero.'));
    }
    return _repository.send(params);
  }
}
