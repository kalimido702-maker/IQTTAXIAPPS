import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base UseCase contract for Clean Architecture
/// [T] is the return type
/// [Params] is the input parameters type
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when a UseCase doesn't need parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
