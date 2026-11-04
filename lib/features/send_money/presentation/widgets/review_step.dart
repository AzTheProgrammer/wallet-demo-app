import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_confirm_sheet.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.state, super.key});

  final SendMoneyState state;

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<SendMoneyBloc>();
    final approved = await confirmWithPin(
      context,
      reason: 'Approve your payment of ${state.amount.format()}',
    );
    if (approved) bloc.add(const SendMoneyEvent.confirmed());
  }

  @override
  Widget build(BuildContext context) {
    final beneficiary = state.beneficiary;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Check the details', style: context.text.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Text(state.amount.format(), style: context.text.displayMedium),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              DetailRow(label: 'To', value: beneficiary?.name ?? ''),
              DetailRow(label: 'Bank', value: beneficiary?.bank ?? ''),
              DetailRow(
                label: 'Account',
                value: beneficiary?.accountNumber ?? '',
              ),
              DetailRow(label: 'From', value: state.account?.name ?? ''),
              DetailRow(label: 'Reference', value: state.reference),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Approve and send',
          icon: Icons.lock_outline_rounded,
          onPressed: () => _confirm(context),
        ),
      ],
    );
  }
}
