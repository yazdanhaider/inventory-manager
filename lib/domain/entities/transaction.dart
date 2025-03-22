import 'package:equatable/equatable.dart';

enum TransactionType { stockIn, stockOut }

class Transaction extends Equatable {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final TransactionType type;
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, itemId, itemName, quantity, type, timestamp];
}
