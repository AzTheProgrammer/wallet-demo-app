import 'package:injectable/injectable.dart';

@lazySingleton
class DemoConfig {
  DemoConfig()
    : failureRate =
          double.tryParse(const String.fromEnvironment('MOCK_FAILURE_RATE')) ??
          0.02,
      minLatency = const Duration(
        milliseconds: int.fromEnvironment(
          'MOCK_MIN_LATENCY',
          defaultValue: 300,
        ),
      ),
      maxLatency = const Duration(
        milliseconds: int.fromEnvironment(
          'MOCK_MAX_LATENCY',
          defaultValue: 900,
        ),
      );

  double failureRate;
  Duration minLatency;
  Duration maxLatency;
  bool offline = false;
}
