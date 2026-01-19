import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/notification_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository;

  NotificationsBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationsState()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationsMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));

    try {
      final response = await _repository.getNotifications(page: 1);
      emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: response.notifications,
        unreadCount: response.unreadCount,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasReachedMax: response.page >= response.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.hasReachedMax) return;

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getNotifications(page: nextPage);

      emit(state.copyWith(
        notifications: [...state.notifications, ...response.notifications],
        unreadCount: response.unreadCount,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasReachedMax: response.page >= response.totalPages,
      ));
    } catch (e) {
      // Silently fail for load more
    }
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);

      final updatedNotifications = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return Notification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationsMarkAllAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAllAsRead();

      final updatedNotifications = state.notifications.map((n) {
        return Notification(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (e) {
      // Silently fail
    }
  }
}
