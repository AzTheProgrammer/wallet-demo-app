import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';

abstract class TransactionRepository {
  Future<Either<Failure, TransactionPage>> getTransactions(
    TransactionQuery query,
  );

  Future<Either<Failure, Transaction>> getTransaction(String id);

  Stream<void> watchChanges();
}
