import 'package:equatable/equatable.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';

enum DateRangeFilter {
  all('Any time', null),
  week('Last 7 days', 7),
  month('Last 30 days', 30),
  quarter('Last 90 days', 90);

  const DateRangeFilter(this.label, this.days);

  final String label;
  final int? days;
}

class TransactionFilters extends Equatable {
  const TransactionFilters({
    this.types = const {},
    this.range = DateRangeFilter.all,
  });

  final Set<TransactionType> types;
  final DateRangeFilter range;

  int get activeCount => types.length + (range == DateRangeFilter.all ? 0 : 1);

  @override
  List<Object?> get props => [types, range];
}
