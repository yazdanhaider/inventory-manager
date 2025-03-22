import 'dart:convert';
import 'package:googleapis/sheets/v4.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/transaction.dart';
import '../../models/inventory_item_model.dart';
import '../../models/transaction_model.dart';
import '../../models/notification_model.dart';

abstract class SheetsRemoteDataSource {
  /// Fetches inventory items from Google Sheets
  Future<List<InventoryItem>> getInventoryItems();

  /// Adds a new inventory item to Google Sheets
  Future<InventoryItemModel> addInventoryItem(InventoryItemModel item);

  /// Updates stock quantity for an item
  Future<InventoryItem> updateStock(String id, int quantity);

  /// Logs a transaction in Google Sheets
  Future<void> addTransaction(Transaction transaction);

  /// Fetches transactions from Google Sheets
  Future<List<TransactionModel>> getTransactions([int limit = 10]);

  /// Deletes an inventory item from Google Sheets
  Future<bool> deleteInventoryItem(String id);

  /// Adds a notification to Google Sheets
  Future<void> addNotification(NotificationModel notification);
}

/// Original implementation using direct Sheets API
class SheetsRemoteDataSourceImpl implements SheetsRemoteDataSource {
  final SheetsApi sheetsApi;

  SheetsRemoteDataSourceImpl({required this.sheetsApi});

  @override
  Future<List<InventoryItem>> getInventoryItems() async {
    try {
      final response = await sheetsApi.spreadsheets.values.get(
        AppConstants.sheetId,
        AppConstants.inventoryRange,
      );

      final values = response.values;
      if (values == null || values.isEmpty) {
        print("API response values are empty");
        return [];
      }

      // Skip header row and empty rows
      final items =
          values
              .skip(1)
              .where((row) => row.isNotEmpty && row.length >= 5)
              .map((row) {
                try {
                  // Check for empty strings in essential fields
                  if (row[0].toString().isEmpty ||
                      row[1].toString().isEmpty ||
                      row[2].toString().isEmpty) {
                    print("Skipping row with empty essential fields: $row");
                    return null;
                  }

                  // Parse quantity with fallbacks
                  int quantity = 0;
                  try {
                    quantity = int.parse(row[2].toString());
                  } catch (e) {
                    print("Error parsing quantity for row: $row, Error: $e");
                  }

                  // Parse price with fallbacks
                  double price = 0.0;
                  try {
                    price = double.parse(row[3].toString());
                  } catch (e) {
                    print("Error parsing price for row: $row, Error: $e");
                  }

                  // Parse threshold with fallbacks
                  int threshold = 0;
                  try {
                    threshold = int.parse(row[4].toString());
                  } catch (e) {
                    print("Error parsing threshold for row: $row, Error: $e");
                  }

                  // Parse date safely
                  DateTime lastUpdated = DateTime.now(); // Default value
                  try {
                    if (row.length > 5 &&
                        row[5] != null &&
                        row[5].toString().isNotEmpty) {
                      // Try ISO format first
                      try {
                        lastUpdated = DateTime.parse(row[5].toString());
                      } catch (e) {
                        try {
                          // Try custom format
                          final parts = row[5].toString().split(' ');
                          final dateParts = parts[0].split('-');
                          final timeParts =
                              parts.length > 1 ? parts[1].split(':') : ['0'];

                          lastUpdated = DateTime(
                            int.parse(dateParts[0]), // year
                            int.parse(dateParts[1]), // month
                            int.parse(dateParts[2]), // day
                            timeParts.length > 0
                                ? int.parse(timeParts[0])
                                : 0, // hour
                            timeParts.length > 1
                                ? int.parse(timeParts[1])
                                : 0, // minute
                            timeParts.length > 2
                                ? int.parse(timeParts[2])
                                : 0, // second
                          );
                        } catch (e) {
                          print("Error parsing date for row: $row, Error: $e");
                          // Fallback to current date if parsing fails
                          lastUpdated = DateTime.now();
                        }
                      }
                    }
                  } catch (e) {
                    print("Error handling date for row: $row, Error: $e");
                  }

                  return InventoryItemModel(
                    id: row[0].toString(),
                    name: row[1].toString(),
                    quantity: quantity,
                    price: price,
                    threshold: threshold,
                    lastUpdated: lastUpdated,
                  );
                } catch (e) {
                  print("Error processing row: $row, Error: $e");
                  return null;
                }
              })
              .whereType<InventoryItemModel>()
              .toList(); // Filter out null values

      print("Successfully parsed ${items.length} inventory items");
      return items;
    } catch (e) {
      print("Error in getInventoryItems: $e");
      throw ServerException();
    }
  }

  @override
  Future<InventoryItemModel> addInventoryItem(InventoryItemModel item) async {
    try {
      final values = [
        [
          item.id,
          item.name,
          item.quantity.toString(),
          item.price.toString(),
          item.threshold.toString(),
          item.lastUpdated.toIso8601String(),
        ],
      ];

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: values),
        AppConstants.sheetId,
        AppConstants.inventoryRange,
        valueInputOption: 'USER_ENTERED',
      );

      return item;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<InventoryItem> updateStock(String id, int quantity) async {
    try {
      // Get current items
      final items = await getInventoryItems();
      final index = items.indexWhere((item) => item.id == id);

      if (index == -1) {
        throw NotFoundException();
      }

      final item = items[index];
      final updatedItem = InventoryItemModel(
        id: item.id,
        name: item.name,
        quantity: quantity,
        price: item.price,
        threshold: item.threshold,
        lastUpdated: DateTime.now(),
      );

      // Update the item in the sheet
      final rowIndex = index + 2; // +1 for header, +1 for 0-based index
      final range = 'Inventory!A$rowIndex:G$rowIndex';

      await sheetsApi.spreadsheets.values.update(
        ValueRange(
          values: [
            [
              updatedItem.id,
              updatedItem.name,
              updatedItem.quantity.toString(),
              updatedItem.price.toString(),
              updatedItem.threshold.toString(),
              updatedItem.lastUpdated.toIso8601String(),
            ],
          ],
        ),
        AppConstants.sheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );

      return updatedItem;
    } catch (e) {
      if (e is NotFoundException) {
        throw e;
      }
      throw ServerException();
    }
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    try {
      print(
        'Adding transaction: ${transaction.id}, Type: ${transaction.type}, Quantity: ${transaction.quantity}',
      );

      final values = [
        [
          transaction.id,
          transaction.itemId,
          transaction.itemName,
          transaction.quantity.toString(), // Explicitly convert to string
          transaction.type == TransactionType.stockIn ? 'IN' : 'OUT',
          transaction.timestamp.toIso8601String(),
        ],
      ];

      print('Transaction values to send: $values');

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: values),
        AppConstants.sheetId,
        AppConstants.transactionsRange,
        valueInputOption: 'USER_ENTERED',
      );

      print('Transaction added successfully');
    } catch (e) {
      print('Error adding transaction: $e');
      throw ServerException();
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions([int limit = 10]) async {
    try {
      final response = await sheetsApi.spreadsheets.values.get(
        AppConstants.sheetId,
        AppConstants.transactionsRange,
      );

      final values = response.values;
      if (values == null || values.isEmpty || values.length < 2) {
        print("No transaction data available");
        return [];
      }

      // Skip header row and process transactions
      final transactions =
          values
              .skip(1) // Skip header row
              .where((row) => row.isNotEmpty && row.length >= 5)
              .map((row) {
                try {
                  final transactionType =
                      row[4].toString().toUpperCase() == 'IN'
                          ? TransactionType.stockIn
                          : TransactionType.stockOut;

                  // Parse quantity
                  int quantity = 0;
                  try {
                    quantity = int.parse(row[3].toString());
                  } catch (e) {
                    print(
                      "Error parsing quantity for transaction: $row, Error: $e",
                    );
                  }

                  // Parse date with improved handling for custom format
                  DateTime timestamp = DateTime.now();
                  try {
                    if (row.length > 5 &&
                        row[5] != null &&
                        row[5].toString().isNotEmpty) {
                      final dateString = row[5].toString();

                      try {
                        // Try ISO format first
                        timestamp = DateTime.parse(dateString);
                      } catch (e) {
                        try {
                          // Handle custom format like "2025-03-21 1:08:37"
                          final parts = dateString.split(' ');
                          if (parts.length >= 2) {
                            final dateParts = parts[0].split('-');
                            final timeParts = parts[1].split(':');

                            if (dateParts.length == 3 &&
                                timeParts.length >= 2) {
                              final year = int.parse(dateParts[0]);
                              final month = int.parse(dateParts[1]);
                              final day = int.parse(dateParts[2]);
                              final hour = int.parse(timeParts[0]);
                              final minute = int.parse(timeParts[1]);
                              final second =
                                  timeParts.length > 2
                                      ? int.parse(timeParts[2])
                                      : 0;

                              timestamp = DateTime(
                                year,
                                month,
                                day,
                                hour,
                                minute,
                                second,
                              );
                            }
                          }
                        } catch (e) {
                          print(
                            "Error parsing date custom format for transaction: $row, Error: $e",
                          );
                        }
                      }
                    }
                  } catch (e) {
                    print(
                      "Error handling date for transaction: $row, Error: $e",
                    );
                  }

                  return TransactionModel(
                    id: row[0].toString(),
                    itemId: row[1].toString(),
                    itemName: row[2].toString(),
                    quantity: quantity,
                    type: transactionType,
                    timestamp: timestamp,
                  );
                } catch (e) {
                  print("Error processing transaction row: $row, Error: $e");
                  return null;
                }
              })
              .where((tx) => tx != null)
              .cast<TransactionModel>()
              .toList();

      // Sort by timestamp (most recent first) and limit results
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Return limited number of transactions
      return transactions.take(limit).toList();
    } catch (e) {
      print("Error fetching transactions: $e");
      throw ServerException();
    }
  }

  @override
  Future<bool> deleteInventoryItem(String id) async {
    try {
      // Get current items
      final items = await getInventoryItems();
      final index = items.indexWhere((item) => item.id == id);

      if (index == -1) {
        throw NotFoundException();
      }

      // Instead of deleting, we'll mark it as inactive by adding "INACTIVE_" prefix to name
      final item = items[index];
      final updatedItem = InventoryItemModel(
        id: item.id,
        name: "INACTIVE_${item.name}",
        quantity: item.quantity,
        price: item.price,
        threshold: item.threshold,
        lastUpdated: DateTime.now(),
      );

      // Update the item in the sheet
      final rowIndex = index + 2; // +1 for header, +1 for 0-based index
      final range = 'Inventory!A$rowIndex:G$rowIndex';

      await sheetsApi.spreadsheets.values.update(
        ValueRange(
          values: [
            [
              updatedItem.id,
              updatedItem.name,
              updatedItem.quantity.toString(),
              updatedItem.price.toString(),
              updatedItem.threshold.toString(),
              updatedItem.lastUpdated.toIso8601String(),
            ],
          ],
        ),
        AppConstants.sheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );

      // Log transaction
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: updatedItem.id,
        itemName: updatedItem.name,
        quantity: 0,
        type: TransactionType.stockOut,
        timestamp: DateTime.now(),
      );

      await addTransaction(transaction);

      return true;
    } catch (e) {
      if (e is NotFoundException) {
        throw e;
      }
      throw ServerException();
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final values = [
        notification.id,
        notification.itemId,
        notification.itemName,
        notification.quantity.toString(),
        notification.timestamp.toIso8601String(),
      ];

      final request = ValueRange(values: [values]);

      await sheetsApi.spreadsheets.values.append(
        request,
        AppConstants.sheetId,
        AppConstants.notificationsRange,
        valueInputOption: 'USER_ENTERED',
      );

      print('Notification logged to Google Sheets: ${notification.itemName}');
    } catch (e) {
      print('Error logging notification to Google Sheets: $e');
      throw ServerException();
    }
  }
}
