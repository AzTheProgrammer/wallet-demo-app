import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/mock/fixture_loader.dart';
import 'package:wallet_app/core/utils/app_clock.dart';

typedef Json = Map<String, dynamic>;

@lazySingleton
class MockServer {
  MockServer(this._config, this._fixtures, this._clock) : _random = Random();

  final DemoConfig _config;
  final FixtureLoader _fixtures;
  final AppClock _clock;
  final Random _random;
  final Map<String, Object?> _tables = {};
  final _ledgerChanges = StreamController<void>.broadcast();

  Stream<void> get ledgerChanges => _ledgerChanges.stream;

  DateTime get now => _clock.now();

  Random get random => _random;

  Future<T> respond<T>(FutureOr<T> Function() handler) async {
    await Future<void>.delayed(_nextLatency());
    if (_config.offline) throw const OfflineException();
    if (_random.nextDouble() < _config.failureRate) {
      throw const ServerException();
    }
    return handler();
  }

  Future<List<Json>> table(String name) async {
    final cached = _tables[name];
    if (cached is List<Json>) return cached;
    final raw = (await _fixtures.load(name))! as List<dynamic>;
    final rows = raw.map((row) => Json.of(row as Json)).toList();
    _tables[name] = rows;
    return rows;
  }

  Future<Json> document(String name) async {
    final cached = _tables[name];
    if (cached is Json) return cached;
    final row = Json.of((await _fixtures.load(name))! as Json);
    _tables[name] = row;
    return row;
  }

  void notifyLedgerChanged() => _ledgerChanges.add(null);

  String nextId(String prefix) =>
      '$prefix-${now.microsecondsSinceEpoch}-${_random.nextInt(9999)}';

  Duration _nextLatency() {
    final min = _config.minLatency.inMilliseconds;
    final spread = _config.maxLatency.inMilliseconds - min;
    if (spread <= 0) return Duration(milliseconds: min);
    return Duration(milliseconds: min + _random.nextInt(spread));
  }
}
