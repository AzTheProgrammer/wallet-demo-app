import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/domain/repositories/vas_repository.dart';

@injectable
class GetVasProviders implements UseCase<List<VasProvider>, VasKind> {
  const GetVasProviders(this._repository);

  final VasRepository _repository;

  @override
  Future<Either<Failure, List<VasProvider>>> call(VasKind kind) =>
      _repository.getProviders(kind);
}

class VasOptionsParams {
  const VasOptionsParams({required this.kind, required this.providerId});

  final VasKind kind;
  final String providerId;
}

@injectable
class GetVasOptions implements UseCase<List<VasOption>, VasOptionsParams> {
  const GetVasOptions(this._repository);

  final VasRepository _repository;

  @override
  Future<Either<Failure, List<VasOption>>> call(VasOptionsParams params) =>
      _repository.getOptions(params.kind, params.providerId);
}

@injectable
class PurchaseVas implements UseCase<VasReceipt, VasPurchase> {
  const PurchaseVas(this._repository);

  final VasRepository _repository;

  @override
  Future<Either<Failure, VasReceipt>> call(VasPurchase params) async {
    final problem = recipientError(params.kind, params.recipient);
    if (problem != null) return left(ValidationFailure(problem));
    return _repository.purchase(params);
  }

  static String? recipientError(VasKind kind, String recipient) =>
      kind == VasKind.electricity
      ? Validators.meterNumber(recipient)
      : Validators.mobileNumber(recipient);
}
