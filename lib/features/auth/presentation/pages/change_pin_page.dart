import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/features/auth/presentation/change_pin/change_pin_cubit.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_screen_body.dart';

class ChangePinPage extends StatelessWidget {
  const ChangePinPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePinCubit, ChangePinState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) {
        if (state.step != ChangePinStep.done) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Your PIN has changed')));
        onDone();
      },
      builder: (context, state) {
        final cubit = context.read<ChangePinCubit>();
        final (title, subtitle) = switch (state.step) {
          ChangePinStep.current => (
            'Current PIN',
            'Enter the PIN you use today.',
          ),
          ChangePinStep.next => (
            'New PIN',
            'Choose a PIN that is hard to guess.',
          ),
          _ => ('Confirm new PIN', 'Enter your new PIN again.'),
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Change PIN')),
          body: SafeArea(
            child: ResponsiveCenter(
              child: PinScreenBody(
                title: title,
                subtitle: subtitle,
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
