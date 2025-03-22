import 'package:equatable/equatable.dart';
import '../../../domain/entities/inventory_item.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  quantityAsc,
  quantityDesc,
  priceAsc,
  priceDesc,
  dateAsc,
  dateDesc,
}

enum FilterOption { all, lowStock, normal }

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial() : super();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading() : super();
}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final List<InventoryItem> filteredItems;
  final SortOption sortOption;
  final FilterOption filterOption;
  final String searchQuery;

  InventoryLoaded({
    required this.items,
    required this.filteredItems,
    this.sortOption = SortOption.nameAsc,
    this.filterOption = FilterOption.all,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [
    items,
    filteredItems,
    sortOption,
    filterOption,
    searchQuery,
  ];

  InventoryLoaded copyWith({
    List<InventoryItem>? items,
    List<InventoryItem>? filteredItems,
    SortOption? sortOption,
    FilterOption? filterOption,
    String? searchQuery,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      sortOption: sortOption ?? this.sortOption,
      filterOption: filterOption ?? this.filterOption,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InventoryError extends InventoryState {
  final String message;

  InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryItemAdded extends InventoryState {
  final InventoryItem item;

  InventoryItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class InventoryStockUpdated extends InventoryState {
  final InventoryItem item;

  InventoryStockUpdated(this.item);

  @override
  List<Object?> get props => [item];
}

class InventoryItemDeleted extends InventoryState {
  @override
  List<Object?> get props => [];
}
