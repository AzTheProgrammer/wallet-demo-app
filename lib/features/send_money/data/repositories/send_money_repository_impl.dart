import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/send_money/data/datasources/send_money_remote_data_source.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/send_money/domain/repositories/send_money_repository.dart';

@LazySingleton(as: SendMoneyRepository)
class SendMoneyRepositoryImpl implements SendMoneyRepository {
  const SendMoneyRepositoryImpl(this._remote);

  final SendMoneyRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Beneficiary>>> getBeneficiaries() =>
      guard(() async {
        final models = await _remote.getBeneficiaries();
        return models.map((model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Beneficiary>> addBeneficiary(
    NewBeneficiary details,
  ) => guard(() async => (await _remote.addBeneficiary(details)).toEntity());

  @override
  Future<Either<Failure, SendMoneyReceipt>> send(SendMoneyRequest request) =>
      guard(() async => (await _remote.send(request)).toEntity());
}
