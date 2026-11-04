import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/repositories/account_repository.dart';

@injectable
class GetAccounts implements UseCase<List<Account>, NoParams> {
  const GetAccounts(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, List<Account>>> call(NoParams params) =>
      _repository.getAccounts();
}
