import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/option_tile.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';

class AmountStep extends StatelessWidget {
  const AmountStep({required this.state, super.key});

  final SendMoneyState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SendMoneyBloc>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Paying ${state.beneficiary?.name ?? ''}',
          style: context.text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Amount',
          prefixText: 'R ',
          initialValue: state.amountText,
          errorText: state.amountError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          onChanged: (value) => bloc.add(SendMoneyEvent.amountChanged(value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Reference',
          hint: 'Shows on their statement',
          initialValue: state.reference,
          errorText: state.referenceError,
          onChanged: (value) =>
              bloc.add(SendMoneyEvent.referenceChanged(value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Pay from', style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        for (final account in state.accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: OptionTile(
              title: account.name,
              subtitle: account.balance.format(),
              selected: account.id == state.account?.id,
              onTap: () => bloc.add(SendMoneyEvent.accountSelected(account)),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Review payment',
          onPressed: () => bloc.add(const SendMoneyEvent.reviewRequested()),
        ),
      ],
    );
  }
}
