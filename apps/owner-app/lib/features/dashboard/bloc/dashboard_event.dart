import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}

class DashboardTogglePlantStatus extends DashboardEvent {
  final bool isOpen;

  const DashboardTogglePlantStatus({required this.isOpen});

  @override
  List<Object?> get props => [isOpen];
}

class DashboardUnreadCountUpdated extends DashboardEvent {
  final int count;

  const DashboardUnreadCountUpdated({required this.count});

  @override
  List<Object?> get props => [count];
}
