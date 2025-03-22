import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/transaction.dart';
import '../../models/inventory_item_model.dart';
import '../../models/transaction_model.dart';
import '../../models/notification_model.dart';
import 'sheets_remote_datasource.dart';

class GoogleAppsScriptDataSource implements SheetsRemoteDataSource {
  final http.Client client;

  GoogleAppsScriptDataSource({required this.client});

  // Helper method to handle redirects
  Future<http.Response> _followRedirect(http.Response response) async {
    if (response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        final redirectResponse = await client.get(Uri.parse(redirectUrl));
        return redirectResponse;
      }
    }
    return response;
  }

  @override
  Future<List<InventoryItem>> getInventoryItems() async {
    try {
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=getInventoryItems',
      );
      var response = await client.get(url);

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) {
          // Ensure all required fields are properly formatted
          return InventoryItemModel(
            id: item['id'].toString(),
            name: item['name'].toString(),
            quantity:
                item['quantity'] is int
                    ? item['quantity']
                    : int.parse(item['quantity'].toString()),
            price:
                item['price'] is double
                    ? item['price']
                    : double.parse(item['price'].toString()),
            threshold:
                item['threshold'] is int
                    ? item['threshold']
                    : int.parse(item['threshold'].toString()),
            lastUpdated:
                item['lastUpdated'] is String
                    ? DateTime.parse(item['lastUpdated'])
                    : item['lastUpdated'],
          );
        }).toList();
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<InventoryItemModel> addInventoryItem(InventoryItemModel item) async {
    try {
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=addInventoryItem',
      );

      final body = json.encode({
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
        'threshold': item.threshold,
      });

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return item; // Return the original item or parse from response
        } else {
          throw ServerException();
        }
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<InventoryItem> updateStock(String id, int quantity) async {
    try {
      final url = Uri.parse('${AppConstants.appsScriptUrl}?action=updateStock');

      final body = json.encode({'id': id, 'quantity': quantity});

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Handle 302 redirect
      if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          response = await client.get(Uri.parse(redirectUrl));
        }
      }

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          // Parse the updated item from response
          if (jsonResponse['item'] != null) {
            return InventoryItemModel.fromJson(jsonResponse['item']);
          } else {
            // Create a minimal item as fallback
            return InventoryItemModel(
              id: id,
              name: "Unknown",
              quantity: quantity,
              price: 0.0,
              threshold: 0,
              lastUpdated: DateTime.now(),
            );
          }
        } else {
          if (jsonResponse['error'] == 'Item not found') {
            throw NotFoundException();
          }
          throw ServerException();
        }
      } else {
        throw ServerException();
      }
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
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=addTransaction',
      );
      final body = json.encode({
        'id': transaction.id,
        'itemId': transaction.itemId,
        'itemName': transaction.itemName,
        'quantity': transaction.quantity,
        'type': transaction.type == TransactionType.stockIn ? 'IN' : 'OUT',
        'timestamp': transaction.timestamp.toIso8601String(),
      });

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode != 200) {
        throw ServerException();
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions([int limit = 10]) async {
    try {
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=getTransactions&limit=$limit',
      );
      var response = await client.get(url);

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        return jsonData.map((json) {
          // Convert transaction type string to enum
          final type =
              json['type'] == 'IN'
                  ? TransactionType.stockIn
                  : TransactionType.stockOut;

          return TransactionModel(
            id: json['id'].toString(),
            itemId: json['itemId'].toString(),
            itemName: json['itemName'].toString(),
            quantity: json['quantity'],
            type: type,
            timestamp: DateTime.parse(json['timestamp']),
          );
        }).toList();
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<bool> deleteInventoryItem(String id) async {
    try {
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=deleteInventoryItem',
      );
      final body = json.encode({'id': id});

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        } else {
          if (jsonResponse['error'] == 'Item not found') {
            throw NotFoundException();
          }
          throw ServerException();
        }
      } else {
        throw ServerException();
      }
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
      final url = Uri.parse(
        '${AppConstants.appsScriptUrl}?action=addNotification',
      );
      final body = json.encode({
        'id': notification.id,
        'itemId': notification.itemId,
        'itemName': notification.itemName,
        'quantity': notification.quantity,
        'timestamp': notification.timestamp.toIso8601String(),
      });

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Handle redirect if needed
      response = await _followRedirect(response);

      if (response.statusCode != 200) {
        throw ServerException();
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}
