import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/notification_model.dart';

/// Repository contract for notification operations.
abstract class NotificationRepository {
  /// Fetch paginated notifications.
  Future<Either<Failure, (List<NotificationModel>, NotificationPagination)>>
      getNotifications({int page = 1});

  /// Delete a single notification by [id].
  Future<Either<Failure, void>> deleteNotification(String id);

  /// Delete all notifications.
  Future<Either<Failure, void>> clearAllNotifications();
}
