import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/transactions/domain/repositories/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._remote);

  final TransactionRemoteDataSource _remote;

  @override
  Future<Either<Failure, TransactionPage>> getTransactions(
    TransactionQuery query,
  ) => guard(() async => (await _remote.getTransactions(query)).toEntity());

  @override
  Future<Either<Failure, Transaction>> getTransaction(String id) =>
      guard(() async => (await _remote.getTransaction(id)).toEntity());

  @override
  Stream<void> watchChanges() => _remote.watchChanges();
}
