import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/router/home_shell.dart';

import '../helpers/pump_app.dart';

GoRouter router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        for (final path in ['/a', '/b', '/c', '/d'])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (_, _) => Text('page $path'),
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  testWidgets('phones get a bottom bar that switches pages', (tester) async {
    tester.usePhoneScreen();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();
    expect(find.text('page /c'), findsOneWidget);
  });

  testWidgets('wide screens get a rail', (tester) async {
    tester.usePhoneScreen(const Size(1200, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('page /d'), findsOneWidget);
  });
}
