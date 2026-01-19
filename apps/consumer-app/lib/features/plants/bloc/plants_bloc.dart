import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/plant_repository.dart';
import '../models/plant_filter.dart';
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
    on<PlantsFilterUpdated>(_onFilterUpdated);
  }

  Future<void> _onNearbyRequested(
    PlantsNearbyRequested event,
    Emitter<PlantsState> emit,
  ) async {
    final filter = event.filter ?? state.filter;

    emit(state.copyWith(
      status: PlantsStatus.loading,
      currentLatitude: event.latitude,
      currentLongitude: event.longitude,
      filter: filter,
    ));

    try {
      final plants = await _plantRepository.getNearbyPlants(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        filter: filter,
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
    final filter = event.filter ?? state.filter;

    emit(state.copyWith(
      status: PlantsStatus.loading,
      filter: filter,
    ));

    try {
      final result = await _plantRepository.searchPlants(
        query: event.query,
        latitude: event.latitude,
        longitude: event.longitude,
        filter: filter,
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
        filter: state.filter,
      ));
    }
  }

  Future<void> _onFilterUpdated(
    PlantsFilterUpdated event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter));

    // Refresh plants with new filter
    if (state.currentLatitude != null && state.currentLongitude != null) {
      add(PlantsNearbyRequested(
        latitude: state.currentLatitude!,
        longitude: state.currentLongitude!,
        filter: event.filter,
      ));
    }
  }
}
