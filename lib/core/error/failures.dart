import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class OfflineFailure extends Failure {
  const OfflineFailure()
    : super("You're offline. Check your connection and try again.");
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = "We couldn't find that."]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure()
    : super("There isn't enough money in this account.");
}

class InsufficientPointsFailure extends Failure {
  const InsufficientPointsFailure()
    : super("You don't have enough points for this reward.");
}

class InvalidPinFailure extends Failure {
  const InvalidPinFailure(this.attemptsLeft)
    : super('Incorrect PIN. Attempts left: $attemptsLeft.');

  final int attemptsLeft;

  @override
  List<Object?> get props => [message, attemptsLeft];
}

class LockedOutFailure extends Failure {
  const LockedOutFailure(this.until)
    : super('Too many incorrect attempts. Try again shortly.');

  final DateTime until;

  @override
  List<Object?> get props => [message, until];
}

class BiometricFailure extends Failure {
  const BiometricFailure([
    super.message = "We couldn't confirm it's you. Use your PIN instead.",
  ]);
}

class StorageFailure extends Failure {
  const StorageFailure()
    : super("We couldn't read your saved data on this device.");
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('Something unexpected happened.');
}
