import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/dashboard/data/datasources/account_remote_data_source.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/dashboard/domain/repositories/account_repository.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remote);

  final AccountRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Account>>> getAccounts() => guard(() async {
    final models = await _remote.getAccounts();
    return models.map((model) => model.toEntity()).toList();
  });
}
