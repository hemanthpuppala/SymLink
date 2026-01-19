import 'package:equatable/equatable.dart';
import '../repositories/notification_repository.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<Notification> notifications;
  final int unreadCount;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;
  final String? error;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
    this.error,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<Notification>? notifications,
    int? unreadCount,
    int? currentPage,
    int? totalPages,
    bool? hasReachedMax,
    String? error,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        currentPage,
        totalPages,
        hasReachedMax,
        error,
      ];
}
