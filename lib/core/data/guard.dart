import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';

Future<Either<Failure, T>> guard<T>(Future<T> Function() body) async {
  try {
    return right(await body());
  } on AppException catch (error) {
    return left(_toFailure(error));
  } on FormatException {
    return left(const ServerFailure());
  } on TypeError {
    return left(const ServerFailure());
  } on Exception {
    return left(const UnknownFailure());
  }
}

Failure _toFailure(AppException error) => switch (error) {
  OfflineException() => const OfflineFailure(),
  ServerException(:final message) when message != null => ServerFailure(
    message,
  ),
  ServerException() => const ServerFailure(),
  NotFoundException() => const NotFoundFailure(),
  InsufficientFundsException() => const InsufficientFundsFailure(),
  InsufficientPointsException() => const InsufficientPointsFailure(),
  StorageException() => const StorageFailure(),
};
