import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../bloc/plants_bloc.dart';
import '../bloc/plants_event.dart';
import '../bloc/plants_state.dart';
import '../widgets/plant_card.dart';
import '../widgets/filter_sheet.dart';
import '../models/plant_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestLocationAndLoadPlants();
  }

  Future<void> _requestLocationAndLoadPlants() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        context.read<PlantsBloc>().add(PlantsNearbyRequested(
              latitude: position.latitude,
              longitude: position.longitude,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowGrid'),
        actions: [
          BlocBuilder<PlantsBloc, PlantsState>(
            buildWhen: (prev, curr) => prev.filter != curr.filter,
            builder: (context, state) {
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search
            },
          ),
        ],
      ),
      body: BlocBuilder<PlantsBloc, PlantsState>(
        builder: (context, state) {
          if (state.status == PlantsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PlantsStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? 'Failed to load plants',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestLocationAndLoadPlants,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
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
                  const Text(
                    'No water plants found nearby',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestLocationAndLoadPlants,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _requestLocationAndLoadPlants();
            },
            child: Column(
              children: [
                if (state.filter.hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (state.filter.openNow)
                                  _FilterChip(
                                    label: 'Open Now',
                                    onRemove: () {
                                      context.read<PlantsBloc>().add(
                                        PlantsFilterUpdated(state.filter.copyWith(openNow: false)),
                                      );
                                    },
                                  ),
                                if (state.filter.verifiedOnly)
                                  _FilterChip(
                                    label: 'Verified',
                                    onRemove: () {
                                      context.read<PlantsBloc>().add(
                                        PlantsFilterUpdated(state.filter.copyWith(verifiedOnly: false)),
                                      );
                                    },
                                  ),
                                if (state.filter.minTds != null || state.filter.maxTds != null)
                                  _FilterChip(
                                    label: 'TDS: ${state.filter.minTds ?? 0}-${state.filter.maxTds ?? '...'}',
                                    onRemove: () {
                                      context.read<PlantsBloc>().add(
                                        PlantsFilterUpdated(state.filter.copyWith(
                                          clearMinTds: true,
                                          clearMaxTds: true,
                                        )),
                                      );
                                    },
                                  ),
                                if (state.filter.minPrice != null || state.filter.maxPrice != null)
                                  _FilterChip(
                                    label: 'Price: \u20B9${state.filter.minPrice ?? 0}-${state.filter.maxPrice ?? '...'}',
                                    onRemove: () {
                                      context.read<PlantsBloc>().add(
                                        PlantsFilterUpdated(state.filter.copyWith(
                                          clearMinPrice: true,
                                          clearMaxPrice: true,
                                        )),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<PlantsBloc>().add(
                              const PlantsFilterUpdated(PlantFilter()),
                            );
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.plants.length,
                    itemBuilder: (context, index) {
                      final plant = state.plants[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PlantCard(
                          plant: plant,
                          onTap: () => context.push('/plants/${plant.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
