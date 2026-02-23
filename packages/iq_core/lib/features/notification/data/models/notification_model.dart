import 'package:equatable/equatable.dart';

/// Single notification item from the API.
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? image;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      image: json['image'] as String?,
      createdAt: (json['converted_created_at'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, body, image, createdAt];
}

/// Pagination info for notifications.
class NotificationPagination extends Equatable {
  final int currentPage;
  final int totalPages;
  final int total;

  const NotificationPagination({
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>?;
    if (pagination == null) {
      return const NotificationPagination();
    }
    return NotificationPagination(
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasMorePages => currentPage < totalPages;

  @override
  List<Object> get props => [currentPage, totalPages, total];
}
