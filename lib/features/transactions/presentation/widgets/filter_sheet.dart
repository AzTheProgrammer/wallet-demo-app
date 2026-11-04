import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transaction_filters.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({required this.initial, super.key});

  final TransactionFilters initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final Set<TransactionType> _types = {...widget.initial.types};
  late DateRangeFilter _range = widget.initial.range;

  void _toggle(TransactionType type) => setState(() {
    if (!_types.remove(type)) _types.add(type);
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filter activity', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Type', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final type in TransactionType.values)
                FilterChip(
                  label: Text(type.label),
                  selected: _types.contains(type),
                  onSelected: (_) => _toggle(type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Date', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final range in DateRangeFilter.values)
                ChoiceChip(
                  label: Text(range.label),
                  selected: _range == range,
                  onSelected: (_) => setState(() => _range = range),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Show results',
            onPressed: () => Navigator.of(
              context,
            ).pop(TransactionFilters(types: _types, range: _range)),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Clear filters',
            variant: AppButtonVariant.quiet,
            onPressed: () =>
                Navigator.of(context).pop(const TransactionFilters()),
          ),
        ],
      ),
    );
  }
}
