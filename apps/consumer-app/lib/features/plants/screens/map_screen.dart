import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../bloc/plants_bloc.dart';
import '../bloc/plants_event.dart';
import '../bloc/plants_state.dart';
import '../repositories/plant_repository.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/plant_card.dart';
import '../models/plant_filter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  Plant? _selectedPlant;
  bool _showListView = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      context.read<PlantsBloc>().add(PlantsNearbyRequested(
            latitude: position.latitude,
            longitude: position.longitude,
          ));
    } catch (e) {
      // Use default location if unable to get current position
      setState(() {
        _currentPosition = const LatLng(12.9716, 77.5946); // Bangalore
      });
    }
  }

  void _updateMarkers(List<Plant> plants) {
    final markers = <Marker>{};

    for (final plant in plants) {
      markers.add(
        Marker(
          markerId: MarkerId(plant.id),
          position: LatLng(plant.latitude, plant.longitude),
          infoWindow: InfoWindow(
            title: plant.name,
            snippet: plant.address,
            onTap: () => _showPlantDetails(plant),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            plant.isVerified
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            setState(() {
              _selectedPlant = plant;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showPlantDetails(Plant plant) {
    context.push('/plants/${plant.id}');
  }

  void _showFilterSheet() {
    final plantsBloc = context.read<PlantsBloc>();
    FilterSheet.show(
      context,
      initialFilter: plantsBloc.state.filter,
      onApply: (filter) {
        plantsBloc.add(PlantsFilterUpdated(filter));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlantsBloc, PlantsState>(
      listener: (context, state) {
        if (state.status == PlantsStatus.success) {
          _updateMarkers(state.plants);
        }
      },
      builder: (context, state) {
        if (_currentPosition == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              if (_showListView)
                _buildListView(state)
              else
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search water plants...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              context.read<PlantsBloc>().add(PlantsSearchRequested(
                                    query: query,
                                    latitude: _currentPosition?.latitude,
                                    longitude: _currentPosition?.longitude,
                                  ));
                            }
                          },
                        ),
                      ),
                      _buildFilterButton(state),
                    ],
                  ),
                ),
              ),
              if (!_showListView)
                Positioned(
                  bottom: 16 + (_selectedPlant != null ? 180 : 0),
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'toggle',
                        onPressed: () {
                          setState(() {
                            _showListView = !_showListView;
                            _selectedPlant = null;
                          });
                        },
                        child: Icon(_showListView ? Icons.map : Icons.list),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'location',
                        onPressed: () async {
                          if (_currentPosition != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(_currentPosition!),
                            );
                          }
                        },
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'refresh',
                        onPressed: () {
                          context.read<PlantsBloc>().add(PlantsRefreshRequested());
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              if (_showListView)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'toggle_map',
                    onPressed: () {
                      setState(() {
                        _showListView = false;
                      });
                    },
                    child: const Icon(Icons.map),
                  ),
                ),
              if (_selectedPlant != null && !_showListView)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildPlantCard(_selectedPlant!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(PlantsState state) {
    final hasFilters = state.filter.hasActiveFilters;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _showFilterSheet,
          tooltip: 'Filter & Sort',
        ),
        if (hasFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(PlantsState state) {
    final padding = MediaQuery.of(context).padding;

    if (state.status == PlantsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.plants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              state.filter.hasActiveFilters
                  ? 'No plants match your filters'
                  : 'No water plants found nearby',
              textAlign: TextAlign.center,
            ),
            if (state.filter.hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<PlantsBloc>().add(
                    const PlantsFilterUpdated(PlantFilter()),
                  );
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, padding.top + 80, 16, 80),
      itemCount: state.plants.length,
      itemBuilder: (context, index) {
        final plant = state.plants[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlantCard(
            plant: plant,
            onTap: () => _showPlantDetails(plant),
          ),
        );
      },
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (plant.isVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plant.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedPlant = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (plant.distance != null) ...[
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${plant.distance!.toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                if (plant.tdsLevel != null) ...[
                  Icon(Icons.science, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'TDS: ${plant.tdsLevel}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPlantDetails(plant),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/chat/new?plantId=${plant.id}');
                    },
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
