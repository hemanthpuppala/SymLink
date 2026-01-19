import 'package:equatable/equatable.dart';
import '../models/plant_filter.dart';

abstract class PlantsEvent extends Equatable {
  const PlantsEvent();

  @override
  List<Object?> get props => [];
}

class PlantsNearbyRequested extends PlantsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final PlantFilter? filter;

  const PlantsNearbyRequested({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
    this.filter,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, filter];
}

class PlantsSearchRequested extends PlantsEvent {
  final String query;
  final double? latitude;
  final double? longitude;
  final PlantFilter? filter;

  const PlantsSearchRequested({
    required this.query,
    this.latitude,
    this.longitude,
    this.filter,
  });

  @override
  List<Object?> get props => [query, latitude, longitude, filter];
}

class PlantsFilterUpdated extends PlantsEvent {
  final PlantFilter filter;

  const PlantsFilterUpdated(this.filter);

  @override
  List<Object?> get props => [filter];
}

class PlantDetailsRequested extends PlantsEvent {
  final String plantId;

  const PlantDetailsRequested({required this.plantId});

  @override
  List<Object?> get props => [plantId];
}

class PlantsRefreshRequested extends PlantsEvent {}
