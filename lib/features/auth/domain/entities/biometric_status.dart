import 'package:equatable/equatable.dart';

class BiometricStatus extends Equatable {
  const BiometricStatus({required this.available, required this.enabled});

  static const off = BiometricStatus(available: false, enabled: false);

  final bool available;
  final bool enabled;

  bool get canUse => available && enabled;

  @override
  List<Object?> get props => [available, enabled];
}
