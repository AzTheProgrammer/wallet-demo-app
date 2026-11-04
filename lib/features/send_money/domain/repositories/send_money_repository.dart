import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';

abstract class SendMoneyRepository {
  Future<Either<Failure, List<Beneficiary>>> getBeneficiaries();

  Future<Either<Failure, Beneficiary>> addBeneficiary(NewBeneficiary details);

  Future<Either<Failure, SendMoneyReceipt>> send(SendMoneyRequest request);
}
