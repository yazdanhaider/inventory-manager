import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/local/inventory_local_datasource.dart';
import '../datasources/remote/sheets_remote_datasource.dart';
import '../models/inventory_item_model.dart';
import '../models/transaction_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final SheetsRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getInventoryItems();
        await localDataSource.cacheInventoryItems(
          remoteItems.cast<InventoryItemModel>(),
        );
        return Right(remoteItems);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localItems = await localDataSource.getLastInventoryItems();
        return Right(localItems);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> addInventoryItem(
    InventoryItem item,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert InventoryItem to InventoryItemModel before adding
        final itemModel =
            item is InventoryItemModel
                ? item
                : InventoryItemModel(
                  id: item.id,
                  name: item.name,
                  quantity: item.quantity,
                  price: item.price,
                  threshold: item.threshold,
                  lastUpdated: item.lastUpdated,
                );

        final addedItem = await remoteDataSource.addInventoryItem(itemModel);

        // Update local cache
        final localItems = await localDataSource.getLastInventoryItems();
        localItems.add(addedItem as InventoryItemModel);
        await localDataSource.cacheInventoryItems(localItems);

        // Log transaction
        final transaction = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: addedItem.id,
          itemName: addedItem.name,
          quantity: addedItem.quantity,
          type: TransactionType.stockIn,
          timestamp: DateTime.now(),
        );

        await remoteDataSource.addTransaction(transaction);

        return Right(addedItem);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> updateStock(
    String id,
    int quantity,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Get current items to determine the old quantity
        final localItems = await localDataSource.getLastInventoryItems();
        final index = localItems.indexWhere((item) => item.id == id);

        if (index == -1) {
          return Left(NotFoundFailure());
        }

        // Calculate quantity difference before updating
        final oldQuantity = localItems[index].quantity;
        final quantityDifference = quantity - oldQuantity;
        final transactionType =
            quantityDifference > 0
                ? TransactionType.stockIn
                : TransactionType.stockOut;

        // Update stock
        final updatedItem = await remoteDataSource.updateStock(id, quantity);

        // Update local cache
        // Convert to InventoryItemModel if needed
        final updatedItemModel =
            updatedItem is InventoryItemModel
                ? updatedItem
                : InventoryItemModel(
                  id: updatedItem.id,
                  name: updatedItem.name,
                  quantity: updatedItem.quantity,
                  price: updatedItem.price,
                  threshold: updatedItem.threshold,
                  lastUpdated: updatedItem.lastUpdated,
                );

        localItems[index] = updatedItemModel;
        await localDataSource.cacheInventoryItems(localItems);

        // Log transaction with the absolute value of the quantity difference
        final transaction = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: updatedItem.id,
          itemName: updatedItem.name,
          quantity: quantityDifference.abs(), // Use absolute value for quantity
          type: transactionType,
          timestamp: DateTime.now(),
        );

        await remoteDataSource.addTransaction(transaction);

        return Right(updatedItem);
      } on ServerException {
        return Left(ServerFailure());
      } on NotFoundException {
        return Left(NotFoundFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteInventoryItem(id);

        // Update local cache
        final localItems = await localDataSource.getLastInventoryItems();
        final index = localItems.indexWhere((item) => item.id == id);

        if (index != -1) {
          localItems.removeAt(index);
          await localDataSource.cacheInventoryItems(localItems);
        }

        return Right(result);
      } on ServerException {
        return Left(ServerFailure());
      } on NotFoundException {
        return Left(NotFoundFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions([
    int limit = 10,
  ]) async {
    if (await networkInfo.isConnected) {
      try {
        final transactions = await remoteDataSource.getTransactions(limit);
        return Right(transactions);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      // If offline, try to get cached transactions from local datasource
      try {
        final localTransactions = await localDataSource.getLastTransactions();
        // Sort and limit
        localTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return Right(localTransactions.take(limit).toList());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
