import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/failures.dart';
import '../../models/inventory_item_model.dart';
import '../../models/transaction_model.dart';

abstract class InventoryLocalDataSource {
  /// Gets the cached list of inventory items
  Future<List<InventoryItemModel>> getLastInventoryItems();

  /// Caches the inventory items
  Future<void> cacheInventoryItems(List<InventoryItemModel> items);

  /// Gets the cached list of transactions
  Future<List<TransactionModel>> getLastTransactions();

  /// Caches the transactions
  Future<void> cacheTransactions(List<TransactionModel> transactions);
}

const CACHED_INVENTORY_ITEMS = 'CACHED_INVENTORY_ITEMS';
const CACHED_TRANSACTIONS = 'CACHED_TRANSACTIONS';

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final SharedPreferences sharedPreferences;

  InventoryLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<InventoryItemModel>> getLastInventoryItems() {
    final jsonString = sharedPreferences.getString(CACHED_INVENTORY_ITEMS);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return Future.value(
        jsonList.map((item) => InventoryItemModel.fromJson(item)).toList(),
      );
    } else {
      throw CacheFailure();
    }
  }

  @override
  Future<void> cacheInventoryItems(List<InventoryItemModel> items) {
    final List<Map<String, dynamic>> jsonList =
        items.map((item) => item.toJson()).toList();
    return sharedPreferences.setString(
      CACHED_INVENTORY_ITEMS,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<TransactionModel>> getLastTransactions() {
    final jsonString = sharedPreferences.getString(CACHED_TRANSACTIONS);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return Future.value(
        jsonList.map((item) => TransactionModel.fromJson(item)).toList(),
      );
    } else {
      throw CacheFailure();
    }
  }

  @override
  Future<void> cacheTransactions(List<TransactionModel> transactions) {
    final List<Map<String, dynamic>> jsonList =
        transactions.map((item) => item.toJson()).toList();
    return sharedPreferences.setString(
      CACHED_TRANSACTIONS,
      json.encode(jsonList),
    );
  }
}
