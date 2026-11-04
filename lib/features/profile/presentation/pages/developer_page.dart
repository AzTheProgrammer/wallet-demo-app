import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/config/data_source_mode.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/features/profile/presentation/cubit/developer_cubit.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer menu')),
      body: BlocBuilder<DeveloperCubit, DeveloperState>(
        builder: (context, state) {
          final cubit = context.read<DeveloperCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'Data source'),
                  SegmentedButton<DataSourceMode>(
                    showSelectedIcon: false,
                    selected: {state.mode},
                    segments: const [
                      ButtonSegment(
                        value: DataSourceMode.mock,
                        label: Text('Mock'),
                      ),
                      ButtonSegment(
                        value: DataSourceMode.api,
                        label: Text('API (Phase 2)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Simulation'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Failure rate: ${(state.failureRate * 100).round()}%',
                          style: context.text.titleSmall,
                        ),
                        Slider(
                          value: state.failureRate,
                          divisions: 10,
                          label: '${(state.failureRate * 100).round()}%',
                          onChanged: cubit.setFailureRate,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate offline'),
                          value: state.offline,
                          onChanged: (offline) =>
                              cubit.setOffline(offline: offline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    onTap: () => context.push(AppRoutes.designSystem),
                    child: Text(
                      'Open design system',
                      style: context.text.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
