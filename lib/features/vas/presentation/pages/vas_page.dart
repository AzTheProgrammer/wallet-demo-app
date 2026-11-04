import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/receipt_view.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/step_failure_view.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';
import 'package:wallet_app/features/vas/presentation/widgets/vas_steps.dart';

class VasPage extends StatelessWidget {
  const VasPage({super.key});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VasBloc, VasState>(
      builder: (context, state) {
        final canStepBack = const {
          VasStep.recipient,
          VasStep.option,
          VasStep.review,
        }.contains(state.step);
        final isFinal =
            state.step == VasStep.success || state.step == VasStep.processing;
        return PopScope(
          canPop: !canStepBack && state.step != VasStep.processing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && canStepBack) {
              context.read<VasBloc>().add(const VasEvent.stepBack());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Buy ${state.kind.label.toLowerCase()}'),
              automaticallyImplyLeading: !isFinal,
            ),
            body: ResponsiveCenter(child: _stepBody(context, state)),
          ),
        );
      },
    );
  }

  Widget _stepBody(BuildContext context, VasState state) =>
      switch (state.step) {
        VasStep.provider => VasProviderStep(state: state),
        VasStep.recipient => VasRecipientStep(state: state),
        VasStep.option => VasOptionStep(state: state),
        VasStep.review => VasReviewStep(state: state),
        VasStep.processing => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3),
        ),
        VasStep.failure => StepFailureView(
          failure: state.failure!,
          onRetry: () => context.read<VasBloc>().add(const VasEvent.stepBack()),
          onCancel: () => _leave(context),
        ),
        VasStep.success => _receipt(context, state),
      };

  Widget _receipt(BuildContext context, VasState state) {
    final receipt = state.receipt!;
    final token = receipt.token;
    final units = receipt.units;
    return ReceiptView(
      title: '${state.option?.label ?? ''} purchased',
      amount: state.option?.amount.format() ?? '',
      onDone: () => _leave(context),
      highlight: token == null ? null : TokenCard(token: token),
      rows: [
        DetailRow(label: 'Provider', value: state.provider?.name ?? ''),
        DetailRow(label: state.kind.recipientLabel, value: state.recipient),
        if (units != null) DetailRow(label: 'Units', value: units),
        DetailRow(label: 'Reference', value: receipt.reference),
        DetailRow(label: 'Date', value: formatDayTime(receipt.purchasedAt)),
      ],
    );
  }
}
