import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/mock/mock_server.dart';

@lazySingleton
class MockLedger {
  const MockLedger(this._server);

  final MockServer _server;

  Future<Json> debit({
    required String accountId,
    required int amountCents,
    required String title,
    required String type,
    required String reference,
    String? token,
  }) async {
    final accounts = await _server.table('accounts');
    final account = accounts.firstWhere(
      (row) => row['id'] == accountId,
      orElse: () => throw const NotFoundException(),
    );
    final balance = account['balance_cents'] as int;
    if (amountCents > balance) throw const InsufficientFundsException();
    account['balance_cents'] = balance - amountCents;
    final entry = <String, dynamic>{
      'id': _server.nextId('txn'),
      'title': title,
      'type': type,
      'amount_cents': -amountCents,
      'occurred_at': _server.now.toIso8601String(),
      'status': 'completed',
      'reference': reference,
      'account_name': account['name'],
      'token': token,
    };
    (await _server.table('transactions')).insert(0, entry);
    _server.notifyLedgerChanged();
    return entry;
  }
}
