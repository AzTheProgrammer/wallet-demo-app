import 'package:equatable/equatable.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';

class TransactionQuery extends Equatable {
  const TransactionQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.types = const {},
    this.from,
    this.to,
  });

  final int page;
  final int pageSize;
  final String search;
  final Set<TransactionType> types;
  final DateTime? from;
  final DateTime? to;

  bool get hasFilters =>
      search.isNotEmpty || types.isNotEmpty || from != null || to != null;

  @override
  List<Object?> get props => [page, pageSize, search, types, from, to];
}

class TransactionPage extends Equatable {
  const TransactionPage({required this.items, required this.hasMore});

  final List<Transaction> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}
