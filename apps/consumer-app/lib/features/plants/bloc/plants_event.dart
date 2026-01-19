import 'package:equatable/equatable.dart';

abstract class PlantsEvent extends Equatable {
  const PlantsEvent();

  @override
  List<Object?> get props => [];
}

class PlantsNearbyRequested extends PlantsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const PlantsNearbyRequested({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

class PlantsSearchRequested extends PlantsEvent {
  final String query;
  final double? latitude;
  final double? longitude;

  const PlantsSearchRequested({
    required this.query,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [query, latitude, longitude];
}

class PlantDetailsRequested extends PlantsEvent {
  final String plantId;

  const PlantDetailsRequested({required this.plantId});

  @override
  List<Object?> get props => [plantId];
}

class PlantsRefreshRequested extends PlantsEvent {}
