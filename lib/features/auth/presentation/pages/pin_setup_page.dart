import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/features/auth/presentation/pin_setup/pin_setup_cubit.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_screen_body.dart';

class PinSetupPage extends StatelessWidget {
  const PinSetupPage({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinSetupCubit, PinSetupState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) {
        if (state.step == PinSetupStep.done) onComplete();
      },
      builder: (context, state) {
        final cubit = context.read<PinSetupCubit>();
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: state.step == PinSetupStep.biometrics
                ? const _BiometricOffer()
                : ResponsiveCenter(
                    child: PinScreenBody(
                      title: state.step == PinSetupStep.confirm
                          ? 'Confirm your PIN'
                          : 'Create a PIN',
                      subtitle: state.step == PinSetupStep.confirm
                          ? 'Enter the same PIN again.'
                          : 'You will use this to unlock and approve payments.',
                      filled: state.entered.length,
                      error: state.error,
                      enabled: !state.isSaving,
                      onDigit: cubit.digitEntered,
                      onBackspace: cubit.backspace,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _BiometricOffer extends StatelessWidget {
  const _BiometricOffer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PinSetupCubit>();
    return ResponsiveCenter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconTile(
                icon: Icons.fingerprint_rounded,
                size: 64,
                color: context.scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Unlock faster', style: context.text.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Use fingerprint or Face ID to unlock and approve payments.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Turn on biometrics',
              onPressed: () => cubit.chooseBiometrics(enable: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Not now',
              variant: AppButtonVariant.quiet,
              onPressed: () => cubit.chooseBiometrics(enable: false),
            ),
          ],
        ),
      ),
    );
  }
}
