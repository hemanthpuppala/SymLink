import '../../../core/api/api_client.dart';

class Notification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'GENERAL',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationResponse {
  final List<Notification> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int totalPages;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final notificationsList = (data['notifications'] as List? ?? [])
        .map((n) => Notification.fromJson(n as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};

    return NotificationResponse(
      notifications: notificationsList,
      unreadCount: data['unreadCount'] as int? ?? 0,
      total: meta['total'] as int? ?? notificationsList.length,
      page: meta['page'] as int? ?? 1,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }
}

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      '/owner/notifications',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      },
    );
    return NotificationResponse.fromJson(response.data);
  }

  Future<void> markAsRead(String notificationId) async {
    await _apiClient.post('/owner/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post('/owner/notifications/read-all');
  }
}
