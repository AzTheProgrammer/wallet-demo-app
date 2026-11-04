import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/features/transactions/data/models/transaction_model.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';

part 'transaction_page_model.freezed.dart';
part 'transaction_page_model.g.dart';

@freezed
abstract class TransactionPageModel with _$TransactionPageModel {
  const factory TransactionPageModel({
    required List<TransactionModel> items,
    required bool hasMore,
  }) = _TransactionPageModel;

  const TransactionPageModel._();

  factory TransactionPageModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageModelFromJson(json);

  TransactionPage toEntity() => TransactionPage(
    items: items.map((item) => item.toEntity()).toList(),
    hasMore: hasMore,
  );
}
