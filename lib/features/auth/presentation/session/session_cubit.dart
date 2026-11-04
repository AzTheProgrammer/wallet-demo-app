import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';

enum SessionStatus { unknown, onboarding, locked, authenticated }

@lazySingleton
class SessionCubit extends Cubit<SessionStatus> {
  SessionCubit(this._checkPinExists, this._clock)
    : super(SessionStatus.unknown);

  static const backgroundGrace = Duration(seconds: 60);

  final CheckPinExists _checkPinExists;
  final AppClock _clock;
  DateTime? _backgroundedAt;

  Future<void> bootstrap() async {
    final result = await _checkPinExists(const NoParams());
    emit(
      result.fold(
        (_) => SessionStatus.locked,
        (exists) => exists ? SessionStatus.locked : SessionStatus.onboarding,
      ),
    );
  }

  void authenticated() => emit(SessionStatus.authenticated);

  void lock() => emit(SessionStatus.locked);

  void backgrounded() => _backgroundedAt = _clock.now();

  void resumed() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || state != SessionStatus.authenticated) return;
    if (_clock.now().difference(since) >= backgroundGrace) lock();
  }
}
