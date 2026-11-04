import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/transactions/data/models/transaction_model.dart';
import 'package:wallet_app/features/transactions/data/models/transaction_page_model.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionPageModel> getTransactions(TransactionQuery query);

  Future<TransactionModel> getTransaction(String id);

  Stream<void> watchChanges();
}

@mockSource
@LazySingleton(as: TransactionRemoteDataSource)
class MockTransactionDataSource implements TransactionRemoteDataSource {
  const MockTransactionDataSource(this._server);

  final MockServer _server;

  @override
  Future<TransactionPageModel> getTransactions(TransactionQuery query) =>
      _server.respond(() async {
        final rows = await _ledger();
        final matches = rows.map(TransactionModel.fromJson).where((model) {
          return _matches(model, query);
        }).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final start = (query.page - 1) * query.pageSize;
        final items = matches.skip(start).take(query.pageSize).toList();
        return TransactionPageModel(
          items: items,
          hasMore: start + items.length < matches.length,
        );
      });

  @override
  Future<TransactionModel> getTransaction(String id) =>
      _server.respond(() async {
        final rows = await _ledger();
        for (final row in rows) {
          if (row['id'] == id) return TransactionModel.fromJson(row);
        }
        throw const NotFoundException();
      });

  @override
  Stream<void> watchChanges() => _server.ledgerChanges;

  Future<List<Json>> _ledger() async {
    final rows = await _server.table('transactions');
    for (final row in rows) {
      final daysAgo = row.remove('days_ago') as int?;
      if (daysAgo == null) continue;
      final minutes = row.remove('minutes') as int? ?? 0;
      row['occurred_at'] = _server.now
          .subtract(Duration(days: daysAgo, minutes: minutes))
          .toIso8601String();
    }
    return rows;
  }

  bool _matches(TransactionModel model, TransactionQuery query) {
    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty &&
        !model.title.toLowerCase().contains(search) &&
        !model.reference.toLowerCase().contains(search)) {
      return false;
    }
    if (query.types.isNotEmpty && !query.types.contains(model.type)) {
      return false;
    }
    if (query.from != null && model.occurredAt.isBefore(query.from!)) {
      return false;
    }
    if (query.to != null && model.occurredAt.isAfter(query.to!)) return false;
    return true;
  }
}
