import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';

import '../../integration_test/happy_path.dart';

Future<void> loadFonts() async {
  final manifest = await rootBundle.loadString('FontManifest.json');
  for (final family in jsonDecode(manifest) as List<dynamic>) {
    final entry = family as Map<String, dynamic>;
    final loader = FontLoader(entry['family'] as String);
    for (final font in entry['fonts'] as List<dynamic>) {
      final asset = (font as Map<String, dynamic>)['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../docs/screenshots/$name.png'),
  );
}

Future<void> go(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'capture screens',
    skip: !const bool.fromEnvironment('SCREENSHOTS'),
    (tester) async {
      debugDisableShadows = false;
      await tester.runAsync(loadFonts);
      tester.view
        ..physicalSize = const Size(860, 1864)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await startApp(tester);
      await shot(tester, 'onboarding');
      await go(tester, 'Set up my PIN');
      await tapPin(tester, '25804');
      await tapPin(tester, '25804');
      await shot(tester, 'home');

      await go(tester, 'Activity');
      await shot(tester, 'activity');
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await shot(tester, 'filters');
      await go(tester, 'Show results');
      await tester.tap(find.byType(InkWell).at(2));
      await shot(tester, 'detail');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await go(tester, 'Home');
      await go(tester, 'Send');
      await shot(tester, 'send_recipient');
      await go(tester, 'Sipho Dlamini');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '150');
      await tester.enterText(fields.at(1), 'Lunch money');
      await go(tester, 'Review payment');
      await shot(tester, 'send_review');
      await go(tester, 'Approve and send');
      await shot(tester, 'pin_confirm');
      await tapPin(tester, '25804');
      await shot(tester, 'send_success');
      await go(tester, 'Done');

      await go(tester, 'Electricity');
      await go(tester, 'City Power');
      await tester.enterText(find.byType(TextFormField), '12345678901');
      await go(tester, 'Continue');
      await go(tester, 'R200 electricity');
      await go(tester, 'Approve and buy');
      await tapPin(tester, '25804');
      await shot(tester, 'electricity_receipt');
      await go(tester, 'Done');

      await go(tester, 'Rewards');
      await shot(tester, 'rewards');
      await go(tester, 'Profile');
      await shot(tester, 'profile');

      await getIt<SettingsCubit>().setTheme(ThemePreference.dark);
      await shot(tester, 'profile_dark');
      await go(tester, 'Home');
      await shot(tester, 'home_dark');
      await go(tester, 'Rewards');
      await shot(tester, 'rewards_dark');

      getIt<SessionCubit>().lock();
      await shot(tester, 'login_dark');
      debugDisableShadows = true;
    },
  );
}
