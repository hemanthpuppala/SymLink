import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  final bool refresh;

  const NotificationsLoadRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class NotificationsLoadMoreRequested extends NotificationsEvent {}

class NotificationMarkAsReadRequested extends NotificationsEvent {
  final String notificationId;

  const NotificationMarkAsReadRequested({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class NotificationsMarkAllAsReadRequested extends NotificationsEvent {}
