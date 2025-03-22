import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/inventory_item.dart';
import '../blocs/inventory/inventory_bloc.dart';
import '../blocs/inventory/inventory_event.dart';
import '../blocs/inventory/inventory_state.dart';
import '../widgets/inventory_list_item.dart';
import 'add_item_page.dart';
import 'stock_operation_page.dart';
import '../../core/services/notification_service.dart';
import '../../injection_container.dart' as di;
import '../utils/ui_helpers.dart';
import '../widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);

    // Trigger inventory loading when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryBloc>().add(GetInventoryItemsEvent());
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<InventoryBloc>().add(
      SearchInventoryEvent(_searchController.text),
    );
  }

  void _showFilterDialog(BuildContext context, InventoryLoaded state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter & Sort'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      context,
                      'All Items',
                      FilterOption.all,
                      state.filterOption,
                    ),
                    _buildFilterChip(
                      context,
                      'Low Stock',
                      FilterOption.lowStock,
                      state.filterOption,
                    ),
                    _buildFilterChip(
                      context,
                      'Normal Stock',
                      FilterOption.normal,
                      state.filterOption,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sort by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SortOption>(
                  value: state.sortOption,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<InventoryBloc>().add(
                        SortInventoryEvent(value),
                      );
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.nameAsc,
                      child: Text('Name (A-Z)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.nameDesc,
                      child: Text('Name (Z-A)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.quantityAsc,
                      child: Text('Quantity (Low-High)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.quantityDesc,
                      child: Text('Quantity (High-Low)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.priceAsc,
                      child: Text('Price (Low-High)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.priceDesc,
                      child: Text('Price (High-Low)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.dateAsc,
                      child: Text('Date (Oldest)'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.dateDesc,
                      child: Text('Date (Newest)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't trigger the fetch event every build as it will cause an infinite update loop
    // Moved this to initState instead

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoaded) {
                return IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter & Sort',
                  onPressed: () => _showFilterDialog(context, state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Test Notification',
            onPressed: () async {
              final success =
                  await di.sl<NotificationService>().showTestNotification();
              UIHelpers.showSnackBar(
                context,
                message:
                    success
                        ? 'Test notification sent'
                        : 'Failed to send notification',
                isSuccess: success,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoading) {
                  return const InventoryListShimmer();
                } else if (state is InventoryLoaded) {
                  return _buildInventoryList(context, state.filteredItems);
                } else if (state is InventoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<InventoryBloc>().add(
                              GetInventoryItemsEvent(),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('No inventory data available'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    FilterOption option,
    FilterOption selectedOption,
  ) {
    final isSelected = option == selectedOption;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          context.read<InventoryBloc>().add(FilterInventoryEvent(option));
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  Widget _buildInventoryList(BuildContext context, List<InventoryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No inventory items found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some items to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddItemPage()),
                ).then((_) {
                  context.read<InventoryBloc>().add(GetInventoryItemsEvent());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Action buttons section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Add Item button
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddItemPage(),
                    ),
                  ).then((_) {
                    context.read<InventoryBloc>().add(GetInventoryItemsEvent());
                  });
                },
                icon: const Icon(Icons.add_circle),
                label: const Text('+ Add New Item'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Manage Stock button
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockOperationPage(),
                    ),
                  ).then((_) {
                    context.read<InventoryBloc>().add(GetInventoryItemsEvent());
                  });
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Manage Stock In/Out'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Item count and last updated info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} items',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Last updated: ${_getLastUpdatedText(items)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),

        // Inventory list with RefreshIndicator
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<InventoryBloc>().add(GetInventoryItemsEvent());
              // Wait some time to ensure the refresh indicator is visible
              return await Future.delayed(const Duration(milliseconds: 1000));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InventoryListItem(item: item);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getLastUpdatedText(List<InventoryItem> items) {
    if (items.isEmpty) return '';

    // Use a safer approach instead of reduce
    DateTime latestDate = items.first.lastUpdated;

    // Find the most recent date
    for (var item in items) {
      if (item.lastUpdated.isAfter(latestDate)) {
        latestDate = item.lastUpdated;
      }
    }

    // Format the date
    final now = DateTime.now();
    final difference = now.difference(latestDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${latestDate.day}/${latestDate.month}/${latestDate.year}';
    }
  }
}
