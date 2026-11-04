import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';

abstract class VasRepository {
  Future<Either<Failure, List<VasProvider>>> getProviders(VasKind kind);

  Future<Either<Failure, List<VasOption>>> getOptions(
    VasKind kind,
    String providerId,
  );

  Future<Either<Failure, VasReceipt>> purchase(VasPurchase purchase);
}
