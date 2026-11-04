import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/vas/data/datasources/vas_remote_data_source.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/domain/repositories/vas_repository.dart';

@LazySingleton(as: VasRepository)
class VasRepositoryImpl implements VasRepository {
  const VasRepositoryImpl(this._remote);

  final VasRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<VasProvider>>> getProviders(VasKind kind) =>
      guard(() async {
        final models = await _remote.getProviders(kind);
        return models.map((model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<VasOption>>> getOptions(
    VasKind kind,
    String providerId,
  ) => guard(() async {
    final models = await _remote.getOptions(kind, providerId);
    return models.map((model) => model.toEntity()).toList();
  });

  @override
  Future<Either<Failure, VasReceipt>> purchase(VasPurchase purchase) =>
      guard(() async => (await _remote.purchase(purchase)).toEntity());
}
