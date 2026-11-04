import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/app.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:wallet_app/features/auth/data/datasources/biometric_data_source.dart';

class InMemoryAuthStore implements AuthLocalDataSource {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class NoBiometrics implements BiometricDataSource {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

Future<void> startApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await GetIt.instance.reset();
  await configureDependencies();
  getIt
    ..allowReassignment = true
    ..registerSingleton<AuthLocalDataSource>(InMemoryAuthStore())
    ..registerSingleton<BiometricDataSource>(NoBiometrics());
  getIt<DemoConfig>()
    ..failureRate = 0
    ..minLatency = Duration.zero
    ..maxLatency = Duration.zero;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const WalletApp());
  await tester.pumpAndSettle();
}

Future<void> tapPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).last);
    await tester.pumpAndSettle();
  }
}

Future<void> runHappyPath(WidgetTester tester) async {
  await startApp(tester);

  await tester.tap(find.text('Set up my PIN'));
  await tester.pumpAndSettle();
  await tapPin(tester, '25804');
  await tapPin(tester, '25804');

  expect(find.text('Hi Thandi'), findsOneWidget);

  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sipho Dlamini'));
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), '150');
  await tester.enterText(fields.at(1), 'Lunch money');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Review payment'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Approve and send'));
  await tester.pumpAndSettle();
  await tapPin(tester, '25804');
  await tester.pumpAndSettle();

  expect(find.text('Sent to Sipho Dlamini'), findsOneWidget);
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Activity'));
  await tester.pumpAndSettle();

  expect(find.text('Sipho Dlamini'), findsWidgets);
  expect(
    find.textContaining(const Money(-15000).format()),
    findsWidgets,
  );
}
