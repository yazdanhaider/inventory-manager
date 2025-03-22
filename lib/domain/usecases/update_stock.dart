import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class UpdateStock {
  final InventoryRepository repository;

  UpdateStock(this.repository);

  Future<Either<Failure, InventoryItem>> call(String id, int quantity) async {
    return await repository.updateStock(id, quantity);
  }
}
