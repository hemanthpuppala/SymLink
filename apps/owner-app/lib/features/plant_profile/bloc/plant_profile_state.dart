import 'package:equatable/equatable.dart';
import '../repositories/plant_repository.dart';

enum PlantProfileStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  error,
}

class PlantProfileState extends Equatable {
  final PlantProfileStatus status;
  final Plant? plant;
  final List<Plant> plants;
  final String? error;
  final bool isUploading;

  const PlantProfileState({
    this.status = PlantProfileStatus.initial,
    this.plant,
    this.plants = const [],
    this.error,
    this.isUploading = false,
  });

  PlantProfileState copyWith({
    PlantProfileStatus? status,
    Plant? plant,
    List<Plant>? plants,
    String? error,
    bool? isUploading,
  }) {
    return PlantProfileState(
      status: status ?? this.status,
      plant: plant ?? this.plant,
      plants: plants ?? this.plants,
      error: error,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  @override
  List<Object?> get props => [status, plant, plants, error, isUploading];
}
