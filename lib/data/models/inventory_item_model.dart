import '../../domain/entities/inventory_item.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required String id,
    required String name,
    required int quantity,
    required double price,
    required int threshold,
    required DateTime lastUpdated,
  }) : super(
         id: id,
         name: name,
         quantity: quantity,
         price: price,
         threshold: threshold,
         lastUpdated: lastUpdated,
       );

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      threshold: json['threshold'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'threshold': threshold,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
