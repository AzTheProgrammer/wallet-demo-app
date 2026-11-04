import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactions implements UseCase<TransactionPage, TransactionQuery> {
  const GetTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Either<Failure, TransactionPage>> call(TransactionQuery params) =>
      _repository.getTransactions(params);
}

@injectable
class GetRecentTransactions implements UseCase<List<Transaction>, int> {
  const GetRecentTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Either<Failure, List<Transaction>>> call(int count) async {
    final result = await _repository.getTransactions(
      TransactionQuery(pageSize: count),
    );
    return result.map((page) => page.items);
  }
}

@injectable
class GetTransactionById implements UseCase<Transaction, String> {
  const GetTransactionById(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Either<Failure, Transaction>> call(String id) =>
      _repository.getTransaction(id);
}

@injectable
class WatchLedgerChanges {
  const WatchLedgerChanges(this._repository);

  final TransactionRepository _repository;

  Stream<void> call() => _repository.watchChanges();
}
