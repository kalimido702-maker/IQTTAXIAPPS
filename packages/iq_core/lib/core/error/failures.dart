import 'package:equatable/equatable.dart';

/// Base Failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-side failure (API errors)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Cache/Local storage failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network connection failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'لا يوجد اتصال بالإنترنت',
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Location/GPS failure
class LocationFailure extends Failure {
  const LocationFailure({required super.message});
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

/// Unknown/unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'حدث خطأ غير متوقع',
  });
}
