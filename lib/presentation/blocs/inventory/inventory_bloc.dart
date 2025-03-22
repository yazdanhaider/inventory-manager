import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/usecases/get_inventory_items.dart';
import '../../../domain/usecases/add_inventory_item.dart';
import '../../../domain/usecases/update_stock.dart';
import '../../../domain/usecases/delete_inventory_item.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';
import '../../../core/services/notification_service.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryItems getInventoryItems;
  final AddInventoryItem addInventoryItem;
  final UpdateStock updateStock;
  final DeleteInventoryItem deleteInventoryItem;
  final NotificationService notificationService;

  InventoryBloc({
    required this.getInventoryItems,
    required this.addInventoryItem,
    required this.updateStock,
    required this.deleteInventoryItem,
    required this.notificationService,
  }) : super(InventoryInitial()) {
    on<GetInventoryItemsEvent>(_onGetInventoryItems);
    on<AddInventoryItemEvent>(_onAddInventoryItem);
    on<UpdateStockEvent>(_onUpdateStock);
    on<DeleteInventoryItemEvent>(_onDeleteInventoryItem);
    on<SortInventoryEvent>(_onSortInventory);
    on<FilterInventoryEvent>(_onFilterInventory);
    on<SearchInventoryEvent>(_onSearchInventory);
  }

  Future<void> _onGetInventoryItems(
    GetInventoryItemsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    print('GetInventoryItemsEvent: Loading items...');
    emit(InventoryLoading());
    final result = await getInventoryItems();
    result.fold(
      (failure) {
        print(
          'GetInventoryItemsEvent: Error - ${_mapFailureToMessage(failure)}',
        );
        emit(InventoryError(_mapFailureToMessage(failure)));
      },
      (items) {
        print(
          'GetInventoryItemsEvent: Got ${items.length} items from repository',
        );

        // Enable notifications with safe handling
        try {
          notificationService.checkLowStockItems(items);
        } catch (e) {
          print('Error checking low stock items: $e');
        }

        // Filter out inactive items
        final activeItems =
            items.where((item) => !item.name.startsWith('INACTIVE_')).toList();
        print(
          'GetInventoryItemsEvent: ${activeItems.length} active items after filtering',
        );

        // Apply default sorting (name ascending)
        activeItems.sort((a, b) => a.name.compareTo(b.name));

        print('GetInventoryItemsEvent: Emitting InventoryLoaded state');
        emit(InventoryLoaded(items: activeItems, filteredItems: activeItems));
      },
    );
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final result = await addInventoryItem(event.item);
    result.fold(
      (failure) => emit(InventoryError(_mapFailureToMessage(failure))),
      (item) {
        add(GetInventoryItemsEvent()); // Refresh the list
        emit(InventoryItemAdded(item));
      },
    );
  }

  Future<void> _onUpdateStock(
    UpdateStockEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final result = await updateStock(event.id, event.quantity);
    result.fold(
      (failure) => emit(InventoryError(_mapFailureToMessage(failure))),
      (item) {
        add(GetInventoryItemsEvent()); // Refresh the list
        emit(InventoryStockUpdated(item));
      },
    );
  }

  Future<void> _onDeleteInventoryItem(
    DeleteInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final result = await deleteInventoryItem(event.id);
    result.fold(
      (failure) => emit(InventoryError(_mapFailureToMessage(failure))),
      (success) {
        add(GetInventoryItemsEvent()); // Refresh the list
        emit(InventoryItemDeleted());
      },
    );
  }

  void _onSortInventory(
    SortInventoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final items = List<InventoryItem>.from(currentState.items);

      // Apply sorting
      switch (event.sortOption) {
        case SortOption.nameAsc:
          items.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.nameDesc:
          items.sort((a, b) => b.name.compareTo(a.name));
          break;
        case SortOption.quantityAsc:
          items.sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
        case SortOption.quantityDesc:
          items.sort((a, b) => b.quantity.compareTo(a.quantity));
          break;
        case SortOption.priceAsc:
          items.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceDesc:
          items.sort((a, b) => b.price.compareTo(a.price));
          break;
        case SortOption.dateAsc:
          items.sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));
          break;
        case SortOption.dateDesc:
          items.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          break;
      }

      // Apply current filter and search to sorted items
      final filteredItems = _applyFilterAndSearch(
        items,
        currentState.filterOption,
        currentState.searchQuery,
      );

      emit(
        currentState.copyWith(
          items: items,
          filteredItems: filteredItems,
          sortOption: event.sortOption,
        ),
      );
    }
  }

  void _onFilterInventory(
    FilterInventoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;

      // Apply filter and current search to items
      final filteredItems = _applyFilterAndSearch(
        currentState.items,
        event.filterOption,
        currentState.searchQuery,
      );

      emit(
        currentState.copyWith(
          filteredItems: filteredItems,
          filterOption: event.filterOption,
        ),
      );
    }
  }

  void _onSearchInventory(
    SearchInventoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;

      // Apply current filter and new search to items
      final filteredItems = _applyFilterAndSearch(
        currentState.items,
        currentState.filterOption,
        event.query,
      );

      emit(
        currentState.copyWith(
          filteredItems: filteredItems,
          searchQuery: event.query,
        ),
      );
    }
  }

  // Helper method to apply filter and search
  List<InventoryItem> _applyFilterAndSearch(
    List<InventoryItem> items,
    FilterOption filterOption,
    String searchQuery,
  ) {
    // First apply filter
    var result = items;

    switch (filterOption) {
      case FilterOption.all:
        // No filtering needed
        break;
      case FilterOption.lowStock:
        result = items.where((item) => item.quantity < item.threshold).toList();
        break;
      case FilterOption.normal:
        result =
            items.where((item) => item.quantity >= item.threshold).toList();
        break;
    }

    // Then apply search if query is not empty
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result =
          result
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query) ||
                    item.id.toLowerCase().contains(query),
              )
              .toList();
    }

    return result;
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      case NetworkFailure:
        return 'No internet connection';
      case NotFoundFailure:
        return 'Item not found';
      default:
        return 'Unexpected error';
    }
  }
}
