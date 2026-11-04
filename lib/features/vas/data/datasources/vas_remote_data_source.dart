import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/mock/mock_ledger.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/vas/data/models/vas_models.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';

abstract class VasRemoteDataSource {
  Future<List<VasProviderModel>> getProviders(VasKind kind);

  Future<List<VasOptionModel>> getOptions(VasKind kind, String providerId);

  Future<VasReceiptModel> purchase(VasPurchase purchase);
}

@mockSource
@LazySingleton(as: VasRemoteDataSource)
class MockVasDataSource implements VasRemoteDataSource {
  const MockVasDataSource(this._server, this._ledger);

  static const _centsPerUnit = 320;

  final MockServer _server;
  final MockLedger _ledger;

  @override
  Future<List<VasProviderModel>> getProviders(VasKind kind) =>
      _server.respond(() async {
        final rows = await _server.table('vas_providers');
        return rows
            .map(VasProviderModel.fromJson)
            .where((provider) => provider.kinds.contains(kind))
            .toList();
      });

  @override
  Future<List<VasOptionModel>> getOptions(VasKind kind, String providerId) =>
      _server.respond(() async {
        final rows = await _server.table('vas_options');
        return rows
            .map(VasOptionModel.fromJson)
            .where(
              (option) =>
                  option.kind == kind &&
                  (option.providerId == null ||
                      option.providerId == providerId),
            )
            .toList();
      });

  @override
  Future<VasReceiptModel> purchase(VasPurchase purchase) => _server.respond(
    () async {
      final isElectricity = purchase.kind == VasKind.electricity;
      final token = isElectricity ? _newToken() : null;
      final reference = 'VAS${_server.random.nextInt(89999999) + 10000000}';
      final entry = await _ledger.debit(
        accountId: purchase.accountId,
        amountCents: purchase.option.amount.cents,
        title: '${purchase.provider.name} ${purchase.kind.label.toLowerCase()}',
        type: purchase.kind.name,
        reference: reference,
        token: token,
      );
      return VasReceiptModel(
        transactionId: entry['id'] as String,
        reference: reference,
        purchasedAt: _server.now,
        token: token,
        units: isElectricity ? _units(purchase) : null,
      );
    },
  );

  String _units(VasPurchase purchase) {
    final units = purchase.option.amount.cents / _centsPerUnit;
    return '${units.toStringAsFixed(1)} kWh';
  }

  String _newToken() =>
      List.generate(20, (_) => _server.random.nextInt(10)).join();
}
