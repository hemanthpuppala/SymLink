import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/plant_repository.dart';
import 'plants_event.dart';
import 'plants_state.dart';

class PlantsBloc extends Bloc<PlantsEvent, PlantsState> {
  final PlantRepository _plantRepository;

  PlantsBloc({required PlantRepository plantRepository})
      : _plantRepository = plantRepository,
        super(const PlantsState()) {
    on<PlantsNearbyRequested>(_onNearbyRequested);
    on<PlantsSearchRequested>(_onSearchRequested);
    on<PlantDetailsRequested>(_onDetailsRequested);
    on<PlantsRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onNearbyRequested(
    PlantsNearbyRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      status: PlantsStatus.loading,
      currentLatitude: event.latitude,
      currentLongitude: event.longitude,
    ));

    try {
      final plants = await _plantRepository.getNearbyPlants(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );

      emit(state.copyWith(
        status: PlantsStatus.success,
        plants: plants,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlantsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSearchRequested(
    PlantsSearchRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(status: PlantsStatus.loading));

    try {
      final result = await _plantRepository.searchPlants(
        query: event.query,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      emit(state.copyWith(
        status: PlantsStatus.success,
        plants: result.plants,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlantsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDetailsRequested(
    PlantDetailsRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(status: PlantsStatus.loading));

    try {
      final plant = await _plantRepository.getPlantDetails(event.plantId);

      emit(state.copyWith(
        status: PlantsStatus.success,
        selectedPlant: plant,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlantsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    PlantsRefreshRequested event,
    Emitter<PlantsState> emit,
  ) async {
    if (state.currentLatitude != null && state.currentLongitude != null) {
      add(PlantsNearbyRequested(
        latitude: state.currentLatitude!,
        longitude: state.currentLongitude!,
      ));
    }
  }
}
