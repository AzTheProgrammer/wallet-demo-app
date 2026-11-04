import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/dashboard/data/models/account_model.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountModel>> getAccounts();
}

@mockSource
@LazySingleton(as: AccountRemoteDataSource)
class MockAccountDataSource implements AccountRemoteDataSource {
  const MockAccountDataSource(this._server);

  final MockServer _server;

  @override
  Future<List<AccountModel>> getAccounts() => _server.respond(() async {
    final rows = await _server.table('accounts');
    return rows.map(AccountModel.fromJson).toList();
  });
}
