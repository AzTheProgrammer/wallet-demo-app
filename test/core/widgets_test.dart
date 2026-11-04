import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/router/session_redirect.dart';
import 'package:wallet_app/core/theme/app_theme.dart';
import 'package:wallet_app/core/widgets/animated_money.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/brand_mark.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/option_tile.dart';
import 'package:wallet_app/core/widgets/pin_dots.dart';
import 'package:wallet_app/core/widgets/pin_pad.dart';
import 'package:wallet_app/core/widgets/receipt_view.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/core/widgets/step_failure_view.dart';
import 'package:wallet_app/core/widgets/success_mark.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';

import '../helpers/pump_app.dart';

Widget scaffold(Widget child) => Scaffold(body: child);

void main() {
  group('AppButton', () {
    testWidgets('fires when tapped', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        scaffold(AppButton(label: 'Pay', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Pay'));
      expect(taps, 1);
    });

    testWidgets('shows progress and blocks taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        scaffold(
          AppButton(label: 'Pay', isLoading: true, onPressed: () => taps++),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('renders every variant with an icon', (tester) async {
      await tester.pumpApp(
        scaffold(
          Column(
            children: [
              for (final variant in AppButtonVariant.values)
                AppButton(
                  label: variant.name,
                  variant: variant,
                  icon: Icons.add,
                  onPressed: () {},
                ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsNWidgets(3));
    });
  });

  testWidgets('AppCard reports taps', (tester) async {
    var tapped = false;
    await tester.pumpApp(
      scaffold(AppCard(onTap: () => tapped = true, child: const Text('Card'))),
    );
    await tester.tap(find.text('Card'));
    expect(tapped, isTrue);
  });

  testWidgets('AppTextField shows label, prefix, icon and errors', (
    tester,
  ) async {
    String? changed;
    await tester.pumpApp(
      scaffold(
        AppTextField(
          label: 'Amount',
          prefixText: 'R ',
          prefixIcon: Icons.money,
          errorText: 'Too much',
          onChanged: (value) => changed = value,
        ),
      ),
    );
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Too much'), findsOneWidget);
    expect(find.byIcon(Icons.money), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '10');
    expect(changed, '10');
  });

  group('Skeleton', () {
    testWidgets('is announced as loading', (tester) async {
      await tester.pumpApp(scaffold(const SkeletonList(count: 2)));
      expect(find.byType(SkeletonListTile), findsNWidgets(2));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('animates when motion is allowed', (tester) async {
      tester.usePhoneScreen();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: scaffold(const SkeletonList(count: 1)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShaderMask), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('state views', () {
    testWidgets('FailureView explains and retries', (tester) async {
      var retried = false;
      await tester.pumpApp(
        scaffold(
          FailureView(
            failure: const ServerFailure('Down'),
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text("That didn't work"), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('FailureView has an offline state', (tester) async {
      await tester.pumpApp(
        scaffold(const FailureView(failure: OfflineFailure())),
      );
      expect(find.text('No connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('EmptyView shows its message and action', (tester) async {
      await tester.pumpApp(
        scaffold(
          const EmptyView(
            title: 'Nothing',
            message: 'Still nothing',
            action: Text('Act'),
          ),
        ),
      );
      expect(find.text('Nothing'), findsOneWidget);
      expect(find.text('Act'), findsOneWidget);
    });

    testWidgets('StepFailureView retries and cancels', (tester) async {
      var retried = false;
      var cancelled = false;
      await tester.pumpApp(
        scaffold(
          StepFailureView(
            failure: const OfflineFailure(),
            onRetry: () => retried = true,
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Cancel'));
      expect(retried, isTrue);
      expect(cancelled, isTrue);
    });
  });

  testWidgets('ResponsiveCenter limits width', (tester) async {
    tester.usePhoneScreen(const Size(1200, 800));
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveCenter(maxWidth: 300, child: SizedBox.expand()),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox).last).width, 300);
  });

  testWidgets('AnimatedMoney shows the amount', (tester) async {
    await tester.pumpApp(
      scaffold(const AnimatedMoney(amount: Money(123456))),
    );
    await tester.pumpAndSettle();
    expect(find.text(const Money(123456).format()), findsOneWidget);
    expect(find.bySemanticsLabel(const Money(123456).format()), findsOneWidget);
  });

  testWidgets('AnimatedMoney counts up when motion is allowed', (tester) async {
    tester.usePhoneScreen();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: scaffold(const AnimatedMoney(amount: Money(100000))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(const Money(100000).format()), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(const Money(100000).format()), findsOneWidget);
  });

  group('PinDots', () {
    testWidgets('announces progress', (tester) async {
      await tester.pumpApp(scaffold(const PinDots(filled: 2)));
      expect(
        find.bySemanticsLabel('PIN entry, 2 of 5 digits entered'),
        findsOneWidget,
      );
    });

    testWidgets('renders the error style', (tester) async {
      await tester.pumpApp(scaffold(const PinDots(filled: 2, hasError: true)));
      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });
  });

  group('PinPad', () {
    testWidgets('reports digits, backspace and biometrics', (tester) async {
      final digits = <String>[];
      var backspaces = 0;
      var biometric = 0;
      await tester.pumpApp(
        scaffold(
          PinPad(
            onDigit: digits.add,
            onBackspace: () => backspaces++,
            onBiometric: () => biometric++,
          ),
        ),
      );
      await tester.tap(find.text('7'));
      await tester.tap(find.text('0'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      expect(digits, ['7', '0']);
      expect(backspaces, 1);
      expect(biometric, 1);
    });

    testWidgets('ignores input when disabled', (tester) async {
      final digits = <String>[];
      await tester.pumpApp(
        scaffold(
          PinPad(onDigit: digits.add, onBackspace: () {}, enabled: false),
        ),
      );
      await tester.tap(find.text('7'));
      expect(digits, isEmpty);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });
  });

  group('SuccessMark', () {
    testWidgets('is labelled', (tester) async {
      await tester.pumpApp(scaffold(const SuccessMark()));
      expect(find.bySemanticsLabel('Success'), findsOneWidget);
    });

    testWidgets('plays its animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: scaffold(const SuccessMark())),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  testWidgets('SectionHeader runs its action', (tester) async {
    var tapped = false;
    await tester.pumpApp(
      scaffold(
        SectionHeader(
          title: 'Recent',
          actionLabel: 'See all',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('See all'));
    expect(tapped, isTrue);
  });

  testWidgets('DetailRow shows label and value', (tester) async {
    await tester.pumpApp(
      scaffold(const DetailRow(label: 'Reference', value: 'Rent')),
    );
    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
  });

  testWidgets('IconTile and BrandMark render', (tester) async {
    await tester.pumpApp(
      scaffold(
        const Column(
          children: [
            IconTile(icon: Icons.bolt),
            BrandMark(),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(find.bySemanticsLabel('Wallet'), findsOneWidget);
  });

  testWidgets('OptionTile shows selection and reports taps', (tester) async {
    var tapped = false;
    await tester.pumpApp(
      scaffold(
        OptionTile(
          title: 'Everyday',
          subtitle: 'R 100',
          leading: const Icon(Icons.star),
          trailing: const Text('Go'),
          selected: true,
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tap(find.text('Everyday'));
    expect(tapped, isTrue);
  });

  testWidgets('ReceiptView shows details and finishes', (tester) async {
    var done = false;
    await tester.pumpApp(
      scaffold(
        ReceiptView(
          title: 'Sent',
          amount: 'R 10.00',
          highlight: const Text('Token'),
          rows: const [DetailRow(label: 'Reference', value: 'Rent')],
          onDone: () => done = true,
        ),
      ),
    );
    expect(find.text('Token'), findsOneWidget);
    await tester.tap(find.text('Done'));
    expect(done, isTrue);
  });

  group('sessionRedirect', () {
    test('holds on splash while unknown', () {
      expect(
        sessionRedirect(SessionStatus.unknown, AppRoutes.home),
        AppRoutes.splash,
      );
      expect(sessionRedirect(SessionStatus.unknown, AppRoutes.splash), isNull);
    });

    test('keeps new users in onboarding', () {
      expect(
        sessionRedirect(SessionStatus.onboarding, AppRoutes.home),
        AppRoutes.onboarding,
      );
      expect(
        sessionRedirect(SessionStatus.onboarding, AppRoutes.pinSetup),
        isNull,
      );
    });

    test('sends locked users to login', () {
      expect(
        sessionRedirect(SessionStatus.locked, AppRoutes.send),
        AppRoutes.login,
      );
      expect(sessionRedirect(SessionStatus.locked, AppRoutes.login), isNull);
    });

    test('keeps signed-in users out of public pages', () {
      expect(
        sessionRedirect(SessionStatus.authenticated, AppRoutes.login),
        AppRoutes.home,
      );
      expect(
        sessionRedirect(SessionStatus.authenticated, AppRoutes.send),
        isNull,
      );
    });
  });

  test('routes build their paths', () {
    expect(AppRoutes.vas('data'), '/vas/data');
    expect(AppRoutes.transactionDetail('a', 'home'), '/activity/a?from=home');
  });

  test('themes expose brand colours', () {
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });
}
