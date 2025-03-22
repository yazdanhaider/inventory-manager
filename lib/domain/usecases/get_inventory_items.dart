import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItems {
  final InventoryRepository repository;

  GetInventoryItems(this.repository);

  Future<Either<Failure, List<InventoryItem>>> call() async {
    return await repository.getInventoryItems();
  }
}
