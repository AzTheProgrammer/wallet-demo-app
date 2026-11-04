import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/mock/mock_ledger.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/send_money/data/models/beneficiary_model.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';

abstract class SendMoneyRemoteDataSource {
  Future<List<BeneficiaryModel>> getBeneficiaries();

  Future<BeneficiaryModel> addBeneficiary(NewBeneficiary details);

  Future<SendReceiptModel> send(SendMoneyRequest request);
}

@mockSource
@LazySingleton(as: SendMoneyRemoteDataSource)
class MockSendMoneyDataSource implements SendMoneyRemoteDataSource {
  const MockSendMoneyDataSource(this._server, this._ledger);

  final MockServer _server;
  final MockLedger _ledger;

  @override
  Future<List<BeneficiaryModel>> getBeneficiaries() =>
      _server.respond(() async {
        final rows = await _server.table('beneficiaries');
        return rows.map(BeneficiaryModel.fromJson).toList();
      });

  @override
  Future<BeneficiaryModel> addBeneficiary(NewBeneficiary details) =>
      _server.respond(() async {
        final row = <String, dynamic>{
          'id': _server.nextId('ben'),
          'name': details.name.trim(),
          'bank': details.bank.trim(),
          'account_number': details.accountNumber.replaceAll(' ', ''),
        };
        (await _server.table('beneficiaries')).insert(0, row);
        return BeneficiaryModel.fromJson(row);
      });

  @override
  Future<SendReceiptModel> send(SendMoneyRequest request) =>
      _server.respond(() async {
        final entry = await _ledger.debit(
          accountId: request.fromAccountId,
          amountCents: request.amount.cents,
          title: request.beneficiary.name,
          type: 'transfer',
          reference: request.reference,
        );
        return SendReceiptModel(
          transactionId: entry['id'] as String,
          reference: request.reference,
          sentAt: _server.now,
        );
      });
}
