import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;

  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get current position with permission handling
  Future<Position?> getCurrentPosition({
    required BuildContext context,
    bool showDialog = true,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showDialog && context.mounted) {
        await _showLocationServiceDialog(context);
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (showDialog && context.mounted) {
          _showSnackBar(context, 'Location permission denied');
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (showDialog && context.mounted) {
        await _showPermissionDeniedDialog(context);
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      if (showDialog && context.mounted) {
        _showSnackBar(context, 'Error getting location: $e');
      }
      return null;
    }
  }

  /// Open directions to a location in the device's default map app
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    // Try Google Maps first
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude${destinationName != null ? '&destination_place_id=$destinationName' : ''}',
    );

    // Fallback to geo: URI scheme
    final geoUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude${destinationName != null ? '($destinationName)' : ''}',
    );

    // Try Google Maps
    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }

    // Try geo: URI
    if (await canLaunchUrl(geoUrl)) {
      return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }

    // Fallback to browser
    return await launchUrl(googleMapsUrl, mode: LaunchMode.inAppBrowserView);
  }

  /// Open phone dialer
  Future<bool> openPhoneDialer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showLocationServiceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to discover nearby water plants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings to discover nearby water plants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for manual location entry
class ManualLocationDialog extends StatefulWidget {
  final Function(double latitude, double longitude) onLocationSelected;

  const ManualLocationDialog({super.key, required this.onLocationSelected});

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String? _error;

  // Predefined locations for quick selection
  final List<Map<String, dynamic>> _predefinedLocations = [
    {'name': 'Hyderabad', 'lat': 17.385, 'lng': 78.4867},
    {'name': 'Mumbai', 'lat': 19.076, 'lng': 72.8777},
    {'name': 'Delhi', 'lat': 28.6139, 'lng': 77.209},
    {'name': 'Bangalore', 'lat': 12.9716, 'lng': 77.5946},
    {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707},
    {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
  ];

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submitLocation() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      setState(() => _error = 'Please enter valid coordinates');
      return;
    }

    if (lat < -90 || lat > 90) {
      setState(() => _error = 'Latitude must be between -90 and 90');
      return;
    }

    if (lng < -180 || lng > 180) {
      setState(() => _error = 'Longitude must be between -180 and 180');
      return;
    }

    widget.onLocationSelected(lat, lng);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Location Manually'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Select:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedLocations.map((loc) {
                return ActionChip(
                  label: Text(loc['name']),
                  onPressed: () {
                    widget.onLocationSelected(loc['lat'], loc['lng']);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Or enter coordinates:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 17.385',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 78.4867',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitLocation,
          child: const Text('Set Location'),
        ),
      ],
    );
  }
}
