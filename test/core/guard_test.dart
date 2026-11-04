import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';

void main() {
  test('wraps a value in right', () async {
    expect(await guard(() async => 1), right<Failure, int>(1));
  });

  final cases = <Exception, Failure>{
    const OfflineException(): const OfflineFailure(),
    const ServerException(): const ServerFailure(),
    const ServerException('Down'): const ServerFailure('Down'),
    const NotFoundException(): const NotFoundFailure(),
    const InsufficientFundsException(): const InsufficientFundsFailure(),
    const InsufficientPointsException(): const InsufficientPointsFailure(),
    const StorageException(): const StorageFailure(),
    const FormatException(): const ServerFailure(),
    Exception('boom'): const UnknownFailure(),
  };

  for (final MapEntry(key: error, value: failure) in cases.entries) {
    test('maps ${error.runtimeType} to ${failure.runtimeType}', () async {
      final result = await guard<int>(() async => throw error);
      expect(result, left<Failure, int>(failure));
    });
  }

  test('maps a malformed payload to a server failure', () async {
    final result = await guard<int>(() async {
      const Object value = 'not a number';
      return value as int;
    });
    expect(result, left<Failure, int>(const ServerFailure()));
  });

  test('failures expose comparable props', () {
    final until = DateTime(2026);
    expect(const InvalidPinFailure(2), const InvalidPinFailure(2));
    expect(LockedOutFailure(until), LockedOutFailure(until));
    expect(const BiometricFailure().message, isNotEmpty);
    expect(const ValidationFailure('x').message, 'x');
  });
}
