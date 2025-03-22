import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final int threshold;
  final DateTime lastUpdated;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.threshold,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    quantity,
    price,
    threshold,
    lastUpdated,
  ];
}
