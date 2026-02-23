import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/notification_model.dart';

/// Contract for notification-related API calls.
abstract class NotificationDataSource {
  /// Fetch paginated notifications.
  ///
  /// Calls `GET api/v1/notifications/get-notification?page={page}`.
  Future<Either<Failure, (List<NotificationModel>, NotificationPagination)>>
      getNotifications({int page = 1});

  /// Delete a single notification by its [id].
  ///
  /// Calls `GET api/v1/notifications/delete-notification/{id}`.
  Future<Either<Failure, void>> deleteNotification(String id);

  /// Delete all notifications for the authenticated user.
  ///
  /// Calls `GET api/v1/notifications/delete-all-notification`.
  Future<Either<Failure, void>> clearAllNotifications();
}
