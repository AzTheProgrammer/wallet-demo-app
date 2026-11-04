sealed class AppException implements Exception {
  const AppException();
}

class OfflineException extends AppException {
  const OfflineException();
}

class ServerException extends AppException {
  const ServerException([this.message]);

  final String? message;
}

class NotFoundException extends AppException {
  const NotFoundException();
}

class InsufficientFundsException extends AppException {
  const InsufficientFundsException();
}

class InsufficientPointsException extends AppException {
  const InsufficientPointsException();
}

class StorageException extends AppException {
  const StorageException();
}
