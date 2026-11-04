import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<Account>>> getAccounts();
}
