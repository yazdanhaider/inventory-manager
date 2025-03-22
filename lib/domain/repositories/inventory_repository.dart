import 'package:dartz/dartz.dart';
import '../entities/inventory_item.dart';
import '../entities/transaction.dart';
import '../../core/errors/failures.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems();
  Future<Either<Failure, InventoryItem>> addInventoryItem(InventoryItem item);
  Future<Either<Failure, InventoryItem>> updateStock(String id, int quantity);
  Future<Either<Failure, bool>> deleteInventoryItem(String id);
  Future<Either<Failure, List<Transaction>>> getTransactions([int limit = 10]);
}
