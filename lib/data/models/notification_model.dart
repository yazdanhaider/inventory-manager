import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final DateTime timestamp;

  const NotificationModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, itemId, itemName, quantity, timestamp];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
