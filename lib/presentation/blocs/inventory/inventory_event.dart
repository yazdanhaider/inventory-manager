import 'package:equatable/equatable.dart';
import '../../../domain/entities/inventory_item.dart';
import 'inventory_state.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class GetInventoryItemsEvent extends InventoryEvent {}

class AddInventoryItemEvent extends InventoryEvent {
  final InventoryItem item;

  AddInventoryItemEvent(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateStockEvent extends InventoryEvent {
  final String id;
  final int quantity;

  UpdateStockEvent(this.id, this.quantity);

  @override
  List<Object?> get props => [id, quantity];
}

class DeleteInventoryItemEvent extends InventoryEvent {
  final String id;

  DeleteInventoryItemEvent(this.id);

  @override
  List<Object> get props => [id];
}

class SortInventoryEvent extends InventoryEvent {
  final SortOption sortOption;

  SortInventoryEvent(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}

class FilterInventoryEvent extends InventoryEvent {
  final FilterOption filterOption;

  const FilterInventoryEvent(this.filterOption);

  @override
  List<Object> get props => [filterOption];
}

class SearchInventoryEvent extends InventoryEvent {
  final String query;

  const SearchInventoryEvent(this.query);

  @override
  List<Object> get props => [query];
}
