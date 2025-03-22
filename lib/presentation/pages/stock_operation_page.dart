import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../blocs/inventory/inventory_bloc.dart';
import '../blocs/inventory/inventory_event.dart';
import '../blocs/inventory/inventory_state.dart';
import '../utils/ui_helpers.dart';
import '../widgets/shimmer_loading.dart';
import 'transaction_history_page.dart';
import 'package:intl/intl.dart';
import '../../injection_container.dart' as di;

class StockOperationPage extends StatefulWidget {
  const StockOperationPage({super.key});

  @override
  State<StockOperationPage> createState() => _StockOperationPageState();
}

class _StockOperationPageState extends State<StockOperationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemId;
  int _quantity = 1;
  TransactionType _transactionType = TransactionType.stockIn;
  bool _isLoading = false;
  List<InventoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    // Fetch items when the page loads
    context.read<InventoryBloc>().add(GetInventoryItemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryStockUpdated) {
          // Stock updated successfully - show snackbar and navigate back
          setState(() {
            _isLoading = false;
          });

          final operationType =
              _transactionType == TransactionType.stockIn
                  ? 'Stock In'
                  : 'Stock Out';

          final selectedItemName =
              _items.firstWhere((item) => item.id == _selectedItemId).name;

          // Show success message with details
          UIHelpers.showSnackBar(
            context,
            message:
                '$operationType of $_quantity ${_quantity == 1 ? 'unit' : 'units'} for $selectedItemName was successful!',
            isSuccess: true,
            duration: const Duration(seconds: 2),
          );

          // Navigate back to home page after a short delay to show the snackbar
          Future.delayed(const Duration(milliseconds: 2100), () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        } else if (state is InventoryError) {
          // Show error and reset loading state
          setState(() {
            _isLoading = false;
          });

          // Show error message with details
          UIHelpers.showSnackBar(
            context,
            message: 'Error updating stock: ${state.message}',
            isSuccess: false,
            duration: const Duration(seconds: 3),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock In/Out'), elevation: 2),
        body: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, state) {
            if (state is InventoryLoading && _items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is InventoryLoaded) {
              // Store the items for later use
              _items = state.items;
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<InventoryBloc>().add(GetInventoryItemsEvent());
                // Wait some time to ensure the refresh indicator is visible
                return await Future.delayed(const Duration(milliseconds: 1000));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                _transactionType == TransactionType.stockIn
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _transactionType == TransactionType.stockIn
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _transactionType == TransactionType.stockIn
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                size: 48,
                                color:
                                    _transactionType == TransactionType.stockIn
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _transactionType == TransactionType.stockIn
                                    ? 'Stock In Operation'
                                    : 'Stock Out Operation',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _transactionType == TransactionType.stockIn
                                    ? 'Add items to your inventory'
                                    : 'Remove items from your inventory',
                                style: TextStyle(color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Transaction type selector
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Operation Type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _transactionType =
                                                TransactionType.stockIn;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                _transactionType ==
                                                        TransactionType.stockIn
                                                    ? Colors.green.shade100
                                                    : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _transactionType ==
                                                          TransactionType
                                                              .stockIn
                                                      ? Colors.green
                                                      : Colors.grey.shade300,
                                              width:
                                                  _transactionType ==
                                                          TransactionType
                                                              .stockIn
                                                      ? 2
                                                      : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.add_circle,
                                                color:
                                                    _transactionType ==
                                                            TransactionType
                                                                .stockIn
                                                        ? Colors.green
                                                        : Colors.grey,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Stock In',
                                                style: TextStyle(
                                                  fontWeight:
                                                      _transactionType ==
                                                              TransactionType
                                                                  .stockIn
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color:
                                                      _transactionType ==
                                                              TransactionType
                                                                  .stockIn
                                                          ? Colors.green
                                                          : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _transactionType =
                                                TransactionType.stockOut;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                _transactionType ==
                                                        TransactionType.stockOut
                                                    ? Colors.orange.shade100
                                                    : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _transactionType ==
                                                          TransactionType
                                                              .stockOut
                                                      ? Colors.orange
                                                      : Colors.grey.shade300,
                                              width:
                                                  _transactionType ==
                                                          TransactionType
                                                              .stockOut
                                                      ? 2
                                                      : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.remove_circle,
                                                color:
                                                    _transactionType ==
                                                            TransactionType
                                                                .stockOut
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Stock Out',
                                                style: TextStyle(
                                                  fontWeight:
                                                      _transactionType ==
                                                              TransactionType
                                                                  .stockOut
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color:
                                                      _transactionType ==
                                                              TransactionType
                                                                  .stockOut
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Item selection
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Item',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedItemId,
                                  decoration: const InputDecoration(
                                    labelText: 'Item',
                                    hintText: 'Select an item',
                                    prefixIcon: Icon(Icons.inventory_2),
                                  ),
                                  items:
                                      _items.map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item.id,
                                          child: Text(item.name),
                                        );
                                      }).toList(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select an item';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedItemId = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_selectedItemId != null)
                                  _buildCurrentStockInfo(),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: _quantity.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    hintText: 'Enter quantity',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }

                                    final quantity = int.tryParse(value);
                                    if (quantity == null || quantity <= 0) {
                                      return 'Quantity must be greater than 0';
                                    }

                                    if (_selectedItemId != null &&
                                        _transactionType ==
                                            TransactionType.stockOut) {
                                      final selectedItem = _items.firstWhere(
                                        (item) => item.id == _selectedItemId,
                                      );

                                      if (quantity > selectedItem.quantity) {
                                        return 'Cannot remove more than available stock';
                                      }
                                    }

                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _quantity = int.tryParse(value) ?? 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading || _selectedItemId == null
                                  ? null
                                  : _submitForm,
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: ShimmerLoading(
                                      child: Icon(Icons.save),
                                    ),
                                  )
                                  : Icon(
                                    _transactionType == TransactionType.stockIn
                                        ? Icons.add_circle
                                        : Icons.remove_circle,
                                  ),
                          label: Text(_isLoading ? 'Processing...' : 'Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _transactionType == TransactionType.stockIn
                                    ? Colors.green
                                    : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Recent transactions section
                        _buildRecentTransactionsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStockInfo() {
    final selectedItem = _items.firstWhere(
      (item) => item.id == _selectedItemId,
    );

    final isLowStock = selectedItem.quantity < selectedItem.threshold;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLowStock ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowStock ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isLowStock ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Stock Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLowStock ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Current Quantity: ${selectedItem.quantity}'),
          Text('Threshold: ${selectedItem.threshold}'),
          Text('Price: \$${selectedItem.price.toStringAsFixed(2)}'),
          if (isLowStock)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Low Stock Alert',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return FutureBuilder<List<Transaction>>(
      future: _getRecentTransactions(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final transactions = snapshot.data ?? [];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const TransactionHistoryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (hasError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load transactions',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent transactions found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        transactions.length > 3 ? 3 : transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final isStockIn =
                          transaction.type == TransactionType.stockIn;
                      final date = transaction.timestamp;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isStockIn
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                          child: Icon(
                            isStockIn ? Icons.add : Icons.remove,
                            color: isStockIn ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          isStockIn ? 'Stock In' : 'Stock Out',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(transaction.itemName),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isStockIn
                                  ? '+${transaction.quantity}'
                                  : '-${transaction.quantity}',
                              style: TextStyle(
                                color: isStockIn ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Transaction>> _getRecentTransactions() async {
    try {
      final result = await di.sl<GetTransactions>().call(5);
      return result.fold((failure) => [], (transactions) => transactions);
    } catch (e) {
      print('Error loading recent transactions: $e');
      return [];
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final selectedItem = _items.firstWhere(
        (item) => item.id == _selectedItemId,
      );

      // Calculate new quantity
      final newQuantity =
          _transactionType == TransactionType.stockIn
              ? selectedItem.quantity + _quantity
              : selectedItem.quantity - _quantity;

      // Check if stock would go negative
      if (newQuantity < 0) {
        UIHelpers.showSnackBar(
          context,
          message: 'Error: Cannot reduce stock below zero!',
          isSuccess: false,
        );
        return;
      }

      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Submit update to bloc
      context.read<InventoryBloc>().add(
        UpdateStockEvent(selectedItem.id, newQuantity),
      );
    }
  }
}
