import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/inventory_repository.dart';

class GetTransactions implements UseCase<List<Transaction>, int> {
  final InventoryRepository repository;

  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call([int limit = 10]) {
    return repository.getTransactions(limit);
  }
}
