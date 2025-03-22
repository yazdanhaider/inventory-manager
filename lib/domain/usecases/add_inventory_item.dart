import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class AddInventoryItem {
  final InventoryRepository repository;

  AddInventoryItem(this.repository);

  Future<Either<Failure, InventoryItem>> call(InventoryItem item) async {
    return await repository.addInventoryItem(item);
  }
}
