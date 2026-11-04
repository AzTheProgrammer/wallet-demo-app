import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/option_tile.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_confirm_sheet.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';

class VasProviderStep extends StatelessWidget {
  const VasProviderStep({required this.state, super.key});

  final VasState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VasBloc>();
    return _Loadable(
      state: state,
      onRetry: () => bloc.add(VasEvent.started(state.kind)),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Choose a provider', style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          if (state.providers.isEmpty)
            const EmptyView(
              title: 'No providers',
              message: 'This service is not available right now.',
            ),
          for (final provider in state.providers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OptionTile(
                title: provider.name,
                onTap: () => bloc.add(VasEvent.providerSelected(provider)),
              ),
            ),
        ],
      ),
    );
  }
}

class VasRecipientStep extends StatelessWidget {
  const VasRecipientStep({required this.state, super.key});

  final VasState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VasBloc>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          state.kind == VasKind.electricity ? 'Which meter?' : 'Which number?',
          style: context.text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: state.kind.recipientLabel,
          initialValue: state.recipient,
          errorText: state.recipientError,
          keyboardType: TextInputType.number,
          onChanged: (value) => bloc.add(VasEvent.recipientChanged(value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continue',
          onPressed: () => bloc.add(const VasEvent.recipientSubmitted()),
        ),
      ],
    );
  }
}

class VasOptionStep extends StatelessWidget {
  const VasOptionStep({required this.state, super.key});

  final VasState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VasBloc>();
    return _Loadable(
      state: state,
      onRetry: () => bloc.add(const VasEvent.recipientSubmitted()),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Pick an amount', style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          if (state.options.isEmpty)
            const EmptyView(
              title: 'Nothing to buy',
              message: 'This provider has no options right now.',
            ),
          for (final option in state.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OptionTile(
                title: option.label,
                subtitle: option.detail,
                trailing: Text(
                  option.amount.format(),
                  style: context.text.titleSmall,
                ),
                onTap: () => bloc.add(VasEvent.optionSelected(option)),
              ),
            ),
        ],
      ),
    );
  }
}

class VasReviewStep extends StatelessWidget {
  const VasReviewStep({required this.state, super.key});

  final VasState state;

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<VasBloc>();
    final amount = state.option?.amount.format() ?? '';
    final approved = await confirmWithPin(
      context,
      reason: 'Approve your purchase of $amount',
    );
    if (approved) bloc.add(const VasEvent.confirmed());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Check the details', style: context.text.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Text(
          state.option?.amount.format() ?? '',
          style: context.text.displayMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              DetailRow(label: 'Provider', value: state.provider?.name ?? ''),
              DetailRow(label: 'Product', value: state.option?.label ?? ''),
              DetailRow(
                label: state.kind.recipientLabel,
                value: state.recipient,
              ),
              DetailRow(label: 'Pay from', value: state.account?.name ?? ''),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Approve and buy',
          icon: Icons.lock_outline_rounded,
          onPressed: () => _confirm(context),
        ),
      ],
    );
  }
}

class _Loadable extends StatelessWidget {
  const _Loadable({
    required this.state,
    required this.onRetry,
    required this.child,
  });

  final VasState state;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (state.loadStatus) {
    ViewStatus.failure => FailureView(
      failure: state.failure!,
      onRetry: onRetry,
    ),
    ViewStatus.success => child,
    _ => const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: SkeletonList(count: 4),
    ),
  };
}
