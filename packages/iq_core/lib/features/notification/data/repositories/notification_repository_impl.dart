import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_data_source.dart';
import '../models/notification_model.dart';

/// Production implementation of [NotificationRepository].
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource dataSource;

  const NotificationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, (List<NotificationModel>, NotificationPagination)>>
      getNotifications({int page = 1}) =>
          dataSource.getNotifications(page: page);

  @override
  Future<Either<Failure, void>> deleteNotification(String id) =>
      dataSource.deleteNotification(id);

  @override
  Future<Either<Failure, void>> clearAllNotifications() =>
      dataSource.clearAllNotifications();
}
