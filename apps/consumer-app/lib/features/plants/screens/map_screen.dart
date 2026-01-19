import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../bloc/plants_bloc.dart';
import '../bloc/plants_event.dart';
import '../bloc/plants_state.dart';
import '../repositories/plant_repository.dart';

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
              ),
              Positioned(
                bottom: 16 + (_selectedPlant != null ? 180 : 0),
                right: 16,
                child: Column(
                  children: [
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
              if (_selectedPlant != null)
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
