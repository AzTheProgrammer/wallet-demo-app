import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  void usePhoneScreen([Size size = const Size(420, 1000)]) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  Future<void> pumpApp(
    Widget child, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    usePhoneScreen();
    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        builder: (context, navigator) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: navigator!,
        ),
        home: child,
      ),
    );
  }

  Future<GoRouter> pumpRouted(
    Widget child, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    usePhoneScreen();
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => child)],
      errorBuilder: (_, state) => Scaffold(body: Text('route:${state.uri}')),
    );
    addTearDown(router.dispose);
    await pumpWidget(
      MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
        builder: (context, navigator) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: navigator!,
        ),
      ),
    );
    return router;
  }

  Future<void> enterPin(String pin) async {
    for (final digit in pin.split('')) {
      await tap(find.text(digit).last);
      await pump();
    }
  }
}
