import 'package:equatable/equatable.dart';
import '../repositories/plant_repository.dart';
import '../models/plant_filter.dart';

enum PlantsStatus { initial, loading, success, failure }

class PlantsState extends Equatable {
  final PlantsStatus status;
  final List<Plant> plants;
  final Plant? selectedPlant;
  final String? error;
  final double? currentLatitude;
  final double? currentLongitude;
  final PlantFilter filter;

  const PlantsState({
    this.status = PlantsStatus.initial,
    this.plants = const [],
    this.selectedPlant,
    this.error,
    this.currentLatitude,
    this.currentLongitude,
    this.filter = const PlantFilter(),
  });

  PlantsState copyWith({
    PlantsStatus? status,
    List<Plant>? plants,
    Plant? selectedPlant,
    String? error,
    double? currentLatitude,
    double? currentLongitude,
    PlantFilter? filter,
  }) {
    return PlantsState(
      status: status ?? this.status,
      plants: plants ?? this.plants,
      selectedPlant: selectedPlant ?? this.selectedPlant,
      error: error,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plants,
        selectedPlant,
        error,
        currentLatitude,
        currentLongitude,
        filter,
      ];
}
