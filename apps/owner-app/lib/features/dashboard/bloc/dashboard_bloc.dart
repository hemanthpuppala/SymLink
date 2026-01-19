import 'package:flutter_bloc/flutter_bloc.dart';
import '../../plant_profile/repositories/plant_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final PlantRepository _plantRepository;

  DashboardBloc({required PlantRepository plantRepository})
      : _plantRepository = plantRepository,
        super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardTogglePlantStatus>(_onTogglePlantStatus);
    on<DashboardUnreadCountUpdated>(_onUnreadCountUpdated);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    await _loadDashboardData(emit);
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboardData(emit, showLoading: false);
  }

  Future<void> _loadDashboardData(
    Emitter<DashboardState> emit, {
    bool showLoading = true,
  }) async {
    try {
      final plants = await _plantRepository.getMyPlants();

      if (plants.isEmpty) {
        emit(state.copyWith(
          status: DashboardStatus.loaded,
          plant: null,
          stats: const DashboardStats(),
        ));
        return;
      }

      // Get the first plant (owners typically have one plant)
      final plant = plants.first;

      final plantSummary = PlantSummary(
        id: plant.id,
        name: plant.name,
        address: plant.address,
        isOpen: plant.isActive,
        verificationStatus: plant.isVerified ? 'verified' : 'unverified',
        tdsReading: plant.tdsLevel,
        pricePerLiter: plant.pricePerLiter,
        viewCount: 0, // Would come from analytics endpoint
      );

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        plant: plantSummary,
        // Stats would come from a dedicated analytics endpoint
        stats: const DashboardStats(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onTogglePlantStatus(
    DashboardTogglePlantStatus event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.plant == null) return;

    try {
      await _plantRepository.updatePlantStatus(
        state.plant!.id,
        event.isOpen,
      );

      // Update local state
      final updatedPlant = PlantSummary(
        id: state.plant!.id,
        name: state.plant!.name,
        address: state.plant!.address,
        isOpen: event.isOpen,
        verificationStatus: state.plant!.verificationStatus,
        tdsReading: state.plant!.tdsReading,
        pricePerLiter: state.plant!.pricePerLiter,
        viewCount: state.plant!.viewCount,
      );

      emit(state.copyWith(plant: updatedPlant));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update status: $e'));
    }
  }

  void _onUnreadCountUpdated(
    DashboardUnreadCountUpdated event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(unreadMessageCount: event.count));
  }
}
