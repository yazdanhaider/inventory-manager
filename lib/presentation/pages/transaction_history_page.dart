import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../injection_container.dart' as di;
import '../utils/ui_helpers.dart';
import '../widgets/shimmer_loading.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load up to 50 transactions
      final result = await di.sl<GetTransactions>().call(50);
      result.fold(
        (failure) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to load transactions';
            _isLoading = false;
          });
        },
        (transactions) {
          setState(() {
            _transactions = transactions;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child:
            _isLoading
                ? _buildLoadingView()
                : _hasError
                ? _buildErrorView()
                : _buildTransactionsList(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: const ShimmerLoading(child: CircleAvatar(radius: 20)),
            title: const ShimmerLoading(
              child: SizedBox(height: 16, width: 100),
            ),
            subtitle: const ShimmerLoading(
              child: SizedBox(height: 14, width: 150),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                ShimmerLoading(child: SizedBox(height: 16, width: 40)),
                SizedBox(height: 4),
                ShimmerLoading(child: SizedBox(height: 12, width: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some stock operations to see transactions here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var transaction in _transactions) {
      final date = dateFormat.format(transaction.timestamp);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Sort dates in descending order (newest first)
    final sortedDates =
        groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final transactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            const SizedBox(height: 8),
            ...transactions.map((tx) => _buildTransactionItem(tx)),
            if (index < sortedDates.length - 1) const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    // Convert YYYY-MM-DD to more readable format
    final dateTime = DateFormat('yyyy-MM-dd').parse(date);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String displayDate;
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      displayDate = 'Today';
    } else if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('MMMM d, yyyy').format(dateTime);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayDate,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isStockIn = transaction.type == TransactionType.stockIn;
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: CircleAvatar(
          backgroundColor:
              isStockIn ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isStockIn ? Icons.add : Icons.remove,
            color: isStockIn ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          isStockIn ? 'Stock In' : 'Stock Out',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          transaction.itemName,
          style: const TextStyle(fontSize: 13),
        ),
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
                fontSize: 16,
              ),
            ),
            Text(
              timeFormat.format(transaction.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
