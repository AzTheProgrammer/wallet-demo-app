import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_screen_body.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({required this.onAuthenticated, super.key});

  static const biometricReason = 'Unlock your wallet';

  final VoidCallback onAuthenticated;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinEntryCubit, PinEntryState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PinEntryStatus.success) onAuthenticated();
      },
      builder: (context, state) {
        final cubit = context.read<PinEntryCubit>();
        return Scaffold(
          body: SafeArea(
            child: ResponsiveCenter(
              child: PinScreenBody(
                title: 'Welcome back',
                subtitle: state.isLocked
                    ? 'Locked. Try again in ${state.lockoutSeconds}s.'
                    : 'Enter your PIN to unlock.',
                filled: state.entered.length,
                error: state.isLocked ? null : state.error,
                enabled: state.acceptsInput,
                onDigit: cubit.digitEntered,
                onBackspace: cubit.backspace,
                onBiometric: state.biometricsReady
                    ? () => cubit.useBiometrics(biometricReason)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
