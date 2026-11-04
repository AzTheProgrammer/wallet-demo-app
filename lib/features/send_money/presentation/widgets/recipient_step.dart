import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/option_tile.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/send_money/presentation/widgets/add_beneficiary_sheet.dart';

class RecipientStep extends StatelessWidget {
  const RecipientStep({required this.state, super.key});

  final SendMoneyState state;

  Future<void> _addBeneficiary(BuildContext context) async {
    final bloc = context.read<SendMoneyBloc>();
    final details = await showModalBottomSheet<NewBeneficiary>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddBeneficiarySheet(),
    );
    if (details != null) bloc.add(SendMoneyEvent.beneficiaryAdded(details));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SendMoneyBloc>();
    return switch (state.loadStatus) {
      ViewStatus.failure => FailureView(
        failure: state.failure!,
        onRetry: () => bloc.add(const SendMoneyEvent.started()),
      ),
      ViewStatus.success => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Who are you paying?', style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Add someone new',
            icon: Icons.person_add_alt_rounded,
            variant: AppButtonVariant.secondary,
            isLoading: state.isAddingBeneficiary,
            onPressed: () => _addBeneficiary(context),
          ),
          if (state.failure != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.failure!.message,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.negative,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (state.beneficiaries.isEmpty)
            const EmptyView(
              icon: Icons.people_outline_rounded,
              title: 'No saved people',
              message: 'Add someone to send your first payment.',
            ),
          for (final person in state.beneficiaries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OptionTile(
                title: person.name,
                subtitle: '${person.bank} · ${person.accountNumber}',
                leading: CircleAvatar(
                  backgroundColor: context.scheme.primaryContainer,
                  foregroundColor: context.scheme.onPrimaryContainer,
                  child: Text(person.initials),
                ),
                onTap: () =>
                    bloc.add(SendMoneyEvent.beneficiarySelected(person)),
              ),
            ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonList(),
      ),
    };
  }
}
