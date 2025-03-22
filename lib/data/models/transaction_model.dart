import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required String id,
    required String itemId,
    required String itemName,
    required int quantity,
    required TransactionType type,
    required DateTime timestamp,
  }) : super(
         id: id,
         itemId: itemId,
         itemName: itemName,
         quantity: quantity,
         type: type,
         timestamp: timestamp,
       );

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      type:
          json['type'] == 'stockIn'
              ? TransactionType.stockIn
              : TransactionType.stockOut,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'type': type == TransactionType.stockIn ? 'stockIn' : 'stockOut',
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
