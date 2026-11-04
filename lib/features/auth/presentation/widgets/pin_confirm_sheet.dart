import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/pin_dots.dart';
import 'package:wallet_app/core/widgets/pin_pad.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';

Future<bool> confirmWithPin(
  BuildContext context, {
  required String reason,
  PinEntryCubit Function()? createCubit,
}) async {
  final approved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          (createCubit ?? getIt.call<PinEntryCubit>.call)()
            ..start(biometricReason: reason),
      child: PinConfirmSheet(reason: reason),
    ),
  );
  return approved ?? false;
}

class PinConfirmSheet extends StatelessWidget {
  const PinConfirmSheet({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinEntryCubit, PinEntryState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PinEntryStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<PinEntryCubit>();
        final error = state.error;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your PIN', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(reason, style: context.text.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              PinDots(
                filled: state.entered.length,
                hasError: error != null,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (error != null)
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.negative,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              PinPad(
                onDigit: cubit.digitEntered,
                onBackspace: cubit.backspace,
                enabled: state.acceptsInput,
                onBiometric: state.biometricsReady
                    ? () => cubit.useBiometrics(reason)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
