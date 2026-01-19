import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/plant_repository.dart';
import 'plant_profile_event.dart';
import 'plant_profile_state.dart';

class PlantProfileBloc extends Bloc<PlantProfileEvent, PlantProfileState> {
  final PlantRepository _plantRepository;

  PlantProfileBloc({required PlantRepository plantRepository})
      : _plantRepository = plantRepository,
        super(const PlantProfileState()) {
    on<PlantProfileLoadRequested>(_onLoadRequested);
    on<PlantProfileCreateRequested>(_onCreateRequested);
    on<PlantProfileUpdateRequested>(_onUpdateRequested);
    on<PlantProfileStatusToggleRequested>(_onStatusToggleRequested);
    on<PlantProfilePhotoUploadRequested>(_onPhotoUploadRequested);
    on<PlantProfilePhotoDeleteRequested>(_onPhotoDeleteRequested);
  }

  Future<void> _onLoadRequested(
    PlantProfileLoadRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    emit(state.copyWith(status: PlantProfileStatus.loading));
    try {
      if (event.plantId != null) {
        // Load specific plant
        final plant = await _plantRepository.getPlant(event.plantId!);
        emit(state.copyWith(
          status: PlantProfileStatus.loaded,
          plant: plant,
        ));
      } else {
        // Load all plants
        final plants = await _plantRepository.getMyPlants();
        emit(state.copyWith(
          status: PlantProfileStatus.loaded,
          plants: plants,
          plant: plants.isNotEmpty ? plants.first : null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlantProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateRequested(
    PlantProfileCreateRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    emit(state.copyWith(status: PlantProfileStatus.saving));
    try {
      final plant = await _plantRepository.createPlant(
        name: event.name,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        phone: event.phone,
        description: event.description,
        tdsLevel: event.tdsLevel,
        pricePerLiter: event.pricePerLiter,
        operatingHours: event.operatingHours,
      );
      emit(state.copyWith(
        status: PlantProfileStatus.saved,
        plant: plant,
        plants: [...state.plants, plant],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlantProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateRequested(
    PlantProfileUpdateRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    emit(state.copyWith(status: PlantProfileStatus.saving));
    try {
      final plant = await _plantRepository.updatePlant(
        event.plantId,
        event.updates,
      );

      // Update plant in list
      final updatedPlants = state.plants.map((p) {
        return p.id == plant.id ? plant : p;
      }).toList();

      emit(state.copyWith(
        status: PlantProfileStatus.saved,
        plant: plant,
        plants: updatedPlants,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlantProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onStatusToggleRequested(
    PlantProfileStatusToggleRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    try {
      final plant = await _plantRepository.updatePlantStatus(
        event.plantId,
        event.isActive,
      );

      // Update plant in list
      final updatedPlants = state.plants.map((p) {
        return p.id == plant.id ? plant : p;
      }).toList();

      emit(state.copyWith(
        plant: plant,
        plants: updatedPlants,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to update status: $e',
      ));
    }
  }

  Future<void> _onPhotoUploadRequested(
    PlantProfilePhotoUploadRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    emit(state.copyWith(isUploading: true));
    try {
      final photos = await _plantRepository.uploadPhoto(
        event.plantId,
        event.file,
      );

      // Refresh plant to get updated photos
      final plant = await _plantRepository.getPlant(event.plantId);

      emit(state.copyWith(
        isUploading: false,
        plant: plant,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        error: 'Failed to upload photo: $e',
      ));
    }
  }

  Future<void> _onPhotoDeleteRequested(
    PlantProfilePhotoDeleteRequested event,
    Emitter<PlantProfileState> emit,
  ) async {
    try {
      await _plantRepository.deletePhoto(event.plantId, event.photoIndex);

      // Refresh plant to get updated photos
      final plant = await _plantRepository.getPlant(event.plantId);

      emit(state.copyWith(plant: plant));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to delete photo: $e',
      ));
    }
  }
}
