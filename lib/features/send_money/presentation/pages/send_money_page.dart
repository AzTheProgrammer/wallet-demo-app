import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/receipt_view.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/step_failure_view.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/send_money/presentation/widgets/amount_step.dart';
import 'package:wallet_app/features/send_money/presentation/widgets/recipient_step.dart';
import 'package:wallet_app/features/send_money/presentation/widgets/review_step.dart';

class SendMoneyPage extends StatelessWidget {
  const SendMoneyPage({super.key});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendMoneyBloc, SendMoneyState>(
      builder: (context, state) {
        final bloc = context.read<SendMoneyBloc>();
        final canStepBack =
            state.step == SendMoneyStep.amount ||
            state.step == SendMoneyStep.review;
        final isFinal =
            state.step == SendMoneyStep.success ||
            state.step == SendMoneyStep.processing;
        return PopScope(
          canPop: !canStepBack && state.step != SendMoneyStep.processing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && canStepBack) {
              bloc.add(const SendMoneyEvent.stepBack());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Send money'),
              automaticallyImplyLeading: !isFinal,
            ),
            body: ResponsiveCenter(child: _stepBody(context, state, bloc)),
          ),
        );
      },
    );
  }

  Widget _stepBody(
    BuildContext context,
    SendMoneyState state,
    SendMoneyBloc bloc,
  ) => switch (state.step) {
    SendMoneyStep.recipient => RecipientStep(state: state),
    SendMoneyStep.amount => AmountStep(state: state),
    SendMoneyStep.review => ReviewStep(state: state),
    SendMoneyStep.processing => const Padding(
      padding: EdgeInsets.all(24),
      child: SkeletonList(count: 3),
    ),
    SendMoneyStep.failure => StepFailureView(
      failure: state.failure!,
      onRetry: () => bloc.add(const SendMoneyEvent.stepBack()),
      onCancel: () => _leave(context),
    ),
    SendMoneyStep.success => ReceiptView(
      title: 'Sent to ${state.beneficiary?.name ?? ''}',
      amount: state.amount.format(),
      onDone: () => _leave(context),
      rows: [
        DetailRow(label: 'Reference', value: state.receipt!.reference),
        DetailRow(label: 'From', value: state.account?.name ?? ''),
        DetailRow(label: 'Date', value: formatDayTime(state.receipt!.sentAt)),
      ],
    ),
  };
}
