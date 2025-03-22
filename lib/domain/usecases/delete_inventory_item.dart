import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class DeleteInventoryItem {
  final InventoryRepository repository;

  DeleteInventoryItem(this.repository);

  Future<Either<Failure, bool>> call(String id) async {
    return await repository.deleteInventoryItem(id);
  }
}
