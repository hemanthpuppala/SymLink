import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import '../sync/sync_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static SecureStorage? _storage;

  static void setStorage(SecureStorage storage) {
    _storage = storage;
  }

  static GoRouter get router => _router;

  static final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isPublicRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isPublicRoute) return null;

      // Check if user is authenticated
      if (_storage != null) {
        final token = await _storage!.getAccessToken();
        print('[Router] Checking auth for ${state.matchedLocation}, token: ${token != null ? "present" : "null"}');
        if (token == null) {
          print('[Router] No token, redirecting to /login');
          return '/login';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/plants/:id',
            name: 'plant-details',
            builder: (context, state) {
              final plantId = state.pathParameters['id']!;
              return PlantDetailsScreen(plantId: plantId);
            },
          ),
          GoRoute(
            path: '/chat',
            name: 'chat-list',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:id',
            name: 'chat',
            builder: (context, state) {
              final conversationId = state.pathParameters['id']!;
              return ChatScreen(conversationId: conversationId);
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Placeholder screens - will be implemented in feature modules
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final storage = RepositoryProvider.of<SecureStorage>(context);
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final token = await storage.getAccessToken();

    if (token != null) {
      // User is already authenticated, initialize SyncService and go to home
      print('[Splash] User authenticated, initializing SyncService');
      SyncService.instance.initialize(apiClient.baseUrl, token);
      if (mounted) {
        context.go('/home');
      }
    } else {
      // Not authenticated, go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'FlowGrid',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'consumer@example.com');
  final _passwordController = TextEditingController(text: 'consumer123');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final storage = RepositoryProvider.of<SecureStorage>(context);

      final response = await apiClient.post('/consumer/auth/login', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend wraps response in {success, data}
        final data = response.data['data'];
        final tokens = data?['tokens'];
        print('[Login] Response: ${response.data}');
        print('[Login] Tokens: $tokens');
        if (tokens != null) {
          await storage.saveTokens(
            accessToken: tokens['accessToken'],
            refreshToken: tokens['refreshToken'],
          );

          // Initialize sync service for real-time updates
          SyncService.instance.initialize(
            apiClient.baseUrl,
            tokens['accessToken'],
          );
        }

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumer Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 64, color: Colors.blue),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Register Screen')),
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _totalUnreadCount = 0;
  StreamSubscription? _messageSub;
  StreamSubscription? _conversationSub;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupSyncListeners();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _conversationSub?.cancel();
    super.dispose();
  }

  void _setupSyncListeners() {
    // Listen for new messages - reload unread count
    _messageSub = SyncService.instance.onNewMessage.listen((_) {
      _loadUnreadCount();
    });

    // Listen for conversation updates (e.g., marking as read)
    _conversationSub = SyncService.instance.onConversationUpdated.listen((_) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/conversations');

      if (response.statusCode == 200) {
        final conversations = response.data['data'] ?? [];
        int total = 0;
        for (final conv in conversations) {
          total += (conv['unreadCount'] ?? 0) as int;
        }
        if (mounted) {
          setState(() {
            _totalUnreadCount = total;
          });
        }
      }
    } catch (e) {
      // Silently fail - unread count is not critical
      print('[MainShell] Error loading unread count: $e');
    }
  }

  Widget _buildChatIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat),
        if (_totalUnreadCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _totalUnreadCount > 99 ? '99+' : _totalUnreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: _buildChatIcon(), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/chat');
              // Refresh unread count when entering chat
              _loadUnreadCount();
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _plants = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _plantCreatedSub;
  StreamSubscription? _plantUpdatedSub;

  @override
  void initState() {
    super.initState();
    _ensureSyncConnected();
    _loadPlants();
    _setupSyncListeners();
  }

  @override
  void dispose() {
    _plantCreatedSub?.cancel();
    _plantUpdatedSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureSyncConnected() async {
    if (!SyncService.instance.isConnected) {
      final storage = RepositoryProvider.of<SecureStorage>(context);
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final token = await storage.getAccessToken();
      if (token != null) {
        print('[HomeScreen] Initializing SyncService');
        SyncService.instance.initialize(apiClient.baseUrl, token);
      }
    }
  }

  void _setupSyncListeners() {
    _plantCreatedSub = SyncService.instance.onPlantCreated.listen((_) {
      _loadPlants();
    });

    _plantUpdatedSub = SyncService.instance.onPlantUpdated.listen((_) {
      _loadPlants();
    });
  }

  Future<void> _loadPlants() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/plants/nearby', queryParameters: {
        'latitude': '40.7128',
        'longitude': '-74.006',
        'radiusKm': '10',
      });

      if (response.statusCode == 200) {
        setState(() {
          _plants = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Water Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadPlants();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadPlants, child: const Text('Retry')),
                    ],
                  ),
                )
              : _plants.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No water plants found nearby'),
                          Text('Try expanding your search radius', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPlants,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _plants.length,
                        itemBuilder: (context, index) {
                          final plant = _plants[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: plant['isVerified'] == true ? Colors.green : Colors.grey,
                                child: const Icon(Icons.water_drop, color: Colors.white),
                              ),
                              title: Text(plant['name'] ?? 'Unknown Plant'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plant['address'] ?? 'No address'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (plant['tdsLevel'] != null) ...[
                                        const Icon(Icons.science, size: 14, color: Colors.blue),
                                        Text(' TDS: ${plant['tdsLevel']} ppm', style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 12),
                                      ],
                                      if (plant['pricePerLiter'] != null) ...[
                                        const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                                        Text(' ₹${plant['pricePerLiter']}/L', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                  if (plant['isVerified'] == true)
                                    const Chip(
                                      label: Text('Verified', style: TextStyle(fontSize: 10)),
                                      backgroundColor: Colors.green,
                                      labelStyle: TextStyle(color: Colors.white),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Icon(
                                plant['isActive'] == true ? Icons.check_circle : Icons.cancel,
                                color: plant['isActive'] == true ? Colors.green : Colors.red,
                              ),
                              onTap: () => context.go('/plants/${plant['id']}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _plants = [];
  bool _isLoading = true;
  bool _isGettingLocation = false;
  dynamic _selectedPlant;
  Offset? _selectedPlantOffset;
  StreamSubscription? _plantCreatedSub;
  StreamSubscription? _plantUpdatedSub;

  // Default location (Hyderabad)
  LatLng _currentLocation = const LatLng(17.385, 78.4867);

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndLoadPlants();
    _setupSyncListeners();
  }

  @override
  void dispose() {
    _plantCreatedSub?.cancel();
    _plantUpdatedSub?.cancel();
    super.dispose();
  }

  void _setupSyncListeners() {
    // Listen for plant changes and refresh
    _plantCreatedSub = SyncService.instance.onPlantCreated.listen((_) {
      _loadPlants();
    });

    _plantUpdatedSub = SyncService.instance.onPlantUpdated.listen((_) {
      _loadPlants();
    });
  }

  Future<void> _getCurrentLocationAndLoadPlants() async {
    setState(() => _isGettingLocation = true);

    try {
      // Try to get device location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _currentLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentLocation, 13);
        }
      }
    } catch (e) {
      print('[MapScreen] Error getting location: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }

    // Load plants near current location
    await _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/plants/nearby', queryParameters: {
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'radiusKm': '100', // Increased radius to find more plants
      });

      if (response.statusCode == 200) {
        setState(() {
          _plants = response.data['data'] ?? response.data ?? [];
          _isLoading = false;
        });
        print('[MapScreen] Loaded ${_plants.length} plants');
      }
    } catch (e) {
      print('[MapScreen] Error loading plants: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLocation, 15);
      await _loadPlants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  String _shortenAddress(String address) {
    // Take first 50 characters or first 2 comma-separated parts
    final parts = address.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return address.length > 50 ? '${address.substring(0, 50)}...' : address;
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Water Plants'),
        actions: [
          IconButton(
            icon: _isGettingLocation
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location),
            onPressed: _isGettingLocation ? null : _goToMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13,
              onTap: (_, __) => setState(() => _selectedPlant = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flowgrid.consumer',
              ),
              MarkerLayer(
                markers: _plants.map((plant) {
                  final lat = (plant['latitude'] as num?)?.toDouble() ?? 0;
                  final lng = (plant['longitude'] as num?)?.toDouble() ?? 0;
                  final isVerified = plant['isVerified'] == true;
                  final isSelected = _selectedPlant != null && _selectedPlant['id'] == plant['id'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlant = plant),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isVerified ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.orange : Colors.white, width: isSelected ? 3 : 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isSelected ? 0.5 : 0.3),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.water_drop, color: Colors.white, size: isSelected ? 30 : 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          // Tooltip popup for selected plant
          if (_selectedPlant != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with name, verified badge, close button
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _selectedPlant['name'] ?? 'Unknown',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_selectedPlant['isVerified'] == true) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Colors.white, size: 12),
                                        SizedBox(width: 2),
                                        Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedPlant = null),
                            child: const Icon(Icons.close, size: 20, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Address (shortened)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _shortenAddress(_selectedPlant['address'] ?? 'No address'),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats row: TDS, Price, Phone
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (_selectedPlant['tdsLevel'] != null)
                            _buildStatChip(Icons.science, '${_selectedPlant['tdsLevel']} ppm', Colors.blue),
                          if (_selectedPlant['pricePerLiter'] != null)
                            _buildStatChip(Icons.currency_rupee, '₹${_selectedPlant['pricePerLiter']}/L', Colors.green),
                          if (_selectedPlant['phone'] != null)
                            _buildStatChip(Icons.phone, _selectedPlant['phone'], Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Create or get conversation and navigate to chat
                                try {
                                  final apiClient = RepositoryProvider.of<ApiClient>(context);
                                  final response = await apiClient.get('/consumer/conversations/plant/${_selectedPlant['id']}');
                                  if (response.statusCode == 200 && context.mounted) {
                                    final conversation = response.data['data'];
                                    context.push('/chat/${conversation['id']}');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error starting chat: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.message, size: 18),
                              label: const Text('Message', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/plants/${_selectedPlant['id']}'),
                              icon: const Icon(Icons.open_in_full, size: 18),
                              label: const Text('Details', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPlants,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class PlantDetailsScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailsScreen({super.key, required this.plantId});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  Map<String, dynamic>? _plant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlantDetails();
  }

  Future<void> _loadPlantDetails() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/plants/${widget.plantId}');

      if (response.statusCode == 200) {
        setState(() {
          _plant = response.data['data'] ?? response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDirections() async {
    if (_plant == null) return;

    final lat = (_plant!['latitude'] as num?)?.toDouble();
    final lng = (_plant!['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available'), backgroundColor: Colors.red),
      );
      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _callPhone() async {
    final phone = _plant?['phone'] ?? _plant?['ownerPhone'];
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startChat() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/conversations/plant/${widget.plantId}');
      if (response.statusCode == 200 && mounted) {
        final conversation = response.data['data'];
        context.push('/chat/${conversation['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value ?? 'Not specified', style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantMap() {
    final lat = (_plant?['latitude'] as num?)?.toDouble();
    final lng = (_plant?['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.location_off, size: 60, color: Colors.grey),
        ),
      );
    }

    final plantLocation = LatLng(lat, lng);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: plantLocation,
            initialZoom: 16.0, // ~500m radius view
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable interactions for preview
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flowgrid.consumer',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: plantLocation,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tap to open directions overlay
        Positioned(
          bottom: 8,
          right: 8,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _openDirections,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions, size: 18, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('Get Directions', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plant Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _plant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plant Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? "Plant not found"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPlantDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isVerified = _plant!['isVerified'] == true || _plant!['verificationStatus'] == 'verified';
    final isOpen = _plant!['isActive'] == true || _plant!['isOpen'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_plant!['name'] ?? 'Plant Details'),
        actions: [
          if (isVerified)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.verified, color: Colors.green),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlantDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Zoomed-in map showing plant location
              SizedBox(
                height: 200,
                child: _buildPlantMap(),
              ),

              // Status banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: isOpen ? Colors.green.shade100 : Colors.red.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOpen ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: isOpen ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOpen ? 'Currently Open' : 'Currently Closed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Plant details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and verification badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _plant!['name'] ?? 'Unknown Plant',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Info rows
                    _buildInfoRow(Icons.location_on, 'Address', _plant!['address']),
                    _buildInfoRow(Icons.access_time, 'Operating Hours', _plant!['operatingHours']),
                    _buildInfoRow(Icons.science, 'TDS Level',
                      _plant!['tdsLevel'] != null || _plant!['tdsReading'] != null
                        ? '${_plant!['tdsLevel'] ?? _plant!['tdsReading']} ppm'
                        : null,
                      iconColor: Colors.blue,
                    ),
                    _buildInfoRow(Icons.currency_rupee, 'Price',
                      _plant!['pricePerLiter'] != null
                        ? 'Rs. ${_plant!['pricePerLiter']}/L'
                        : null,
                      iconColor: Colors.green,
                    ),
                    if (_plant!['phone'] != null || _plant!['ownerPhone'] != null)
                      _buildInfoRow(Icons.phone, 'Contact', _plant!['phone'] ?? _plant!['ownerPhone']),

                    if (_plant!['description'] != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_plant!['description']),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Directions button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Call button
              if (_plant!['phone'] != null || _plant!['ownerPhone'] != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callPhone,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (_plant!['phone'] != null || _plant!['ownerPhone'] != null)
                const SizedBox(width: 8),
              // Message button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startChat,
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _messageSub;
  StreamSubscription? _conversationSub;

  @override
  void initState() {
    super.initState();
    _ensureSyncConnected();
    _loadConversations();
    _setupSyncListeners();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _conversationSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureSyncConnected() async {
    if (!SyncService.instance.isConnected) {
      final storage = RepositoryProvider.of<SecureStorage>(context);
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final token = await storage.getAccessToken();
      if (token != null) {
        print('[ChatListScreen] Initializing SyncService');
        SyncService.instance.initialize(apiClient.baseUrl, token);
      }
    }
  }

  void _setupSyncListeners() {
    print('[ChatListScreen] Setting up sync listeners, connected: ${SyncService.instance.isConnected}');

    // Listen for new messages - refresh conversation list
    _messageSub = SyncService.instance.onNewMessage.listen((data) {
      print('[ChatListScreen] Received new message event: $data');
      _loadConversations(silent: true);
    });

    // Listen for conversation updates
    _conversationSub = SyncService.instance.onConversationUpdated.listen((data) {
      print('[ChatListScreen] Received conversation updated event: $data');
      _loadConversations(silent: true);
    });
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/conversations');

      if (response.statusCode == 200) {
        setState(() {
          _conversations = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation from a water plant',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final lastMsg = conv['lastMessage'];
                          final unreadCount = conv['unreadCount'] ?? 0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.water_drop, color: Colors.blue.shade700),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv['plantName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastMsg != null)
                                  Text(
                                    _formatTime(lastMsg['sentAt']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: unreadCount > 0 ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMsg != null
                                        ? '${lastMsg['senderType'] == 'consumer' ? 'You: ' : ''}${lastMsg['content']}'
                                        : 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => context.push('/chat/${conv['id']}').then((_) => _loadConversations(silent: true)),
                          );
                        },
                      ),
                    ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Map<String, dynamic>? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherTyping = false;
  IO.Socket? _socket;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _disconnectWebSocket();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    final storage = RepositoryProvider.of<SecureStorage>(context);
    final token = await storage.getAccessToken();
    if (token == null) return;

    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final baseUrl = apiClient.baseUrl.replaceAll('/v1', '');

    _socket = IO.io(
      '$baseUrl/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      print('[WS] Connected');
      _socket?.emit('join_conversation', {'conversationId': widget.conversationId});
    });

    _socket?.on('new_message', (data) {
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    });

    _socket?.on('user_typing', (data) {
      if (mounted && data['userType'] != 'consumer') {
        setState(() {
          _otherTyping = data['isTyping'] ?? false;
        });
      }
    });

    _socket?.on('message_read', (data) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == data['messageId']);
          if (index != -1) {
            _messages[index]['readAt'] = data['readAt'];
          }
        });
      }
    });

    _socket?.on('message_delivered', (data) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == data['messageId']);
          if (index != -1) {
            _messages[index]['deliveredAt'] = data['deliveredAt'];
          }
        });
      }
    });

    _socket?.onDisconnect((_) => print('[WS] Disconnected'));
    _socket?.onError((err) => print('[WS] Error: $err'));
  }

  void _disconnectWebSocket() {
    _socket?.emit('leave_conversation', {'conversationId': widget.conversationId});
    _socket?.disconnect();
    _socket?.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);

      // Load messages and conversation info
      final response = await apiClient.get('/consumer/conversations/${widget.conversationId}/messages');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _messages = data['messages'] ?? [];
          _conversation = data['conversation'];
          _isLoading = false;
        });

        // Mark as read
        await apiClient.post('/consumer/conversations/${widget.conversationId}/read');

        _scrollToBottom();
      }
    } catch (e) {
      print('[Chat] Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    _typingTimer?.cancel();
    _socket?.emit('typing', {
      'conversationId': widget.conversationId,
      'isTyping': true,
    });

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _socket?.emit('typing', {
        'conversationId': widget.conversationId,
        'isTyping': false,
      });
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.post(
        '/consumer/conversations/${widget.conversationId}/messages',
        data: {'content': content},
      );

      // Add the sent message to the list
      if (response.statusCode == 200 || response.statusCode == 201) {
        final messageData = response.data['data'];
        if (messageData != null && mounted) {
          setState(() {
            _messages.add(messageData);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatMessageTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageStatus(dynamic message) {
    if (message['senderType'] != 'consumer') return const SizedBox.shrink();

    if (message['readAt'] != null) {
      return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    } else if (message['deliveredAt'] != null) {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    } else {
      return const Icon(Icons.done, size: 14, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantName = _conversation?['plantName'] ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plantName, style: const TextStyle(fontSize: 18)),
            if (_otherTyping)
              const Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            else if (_conversation?['plantAddress'] != null)
              Text(
                _conversation!['plantAddress'],
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            const Text('Say hello!'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderType'] == 'consumer';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: 8,
                                left: isMe ? 48 : 0,
                                right: isMe ? 0 : 48,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatMessageTime(message['sentAt']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        _buildMessageStatus(message),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_otherTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0),
                        _TypingDot(delay: 200),
                        _TypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (_) => _onTyping(),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, -_animation.value),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isCheckingDisplayName = false;
  bool? _displayNameAvailable;
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/profile');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _profile = data;
          _displayNameController.text = data['displayName'] ?? '';
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkDisplayNameAvailability(String displayName) async {
    if (displayName.isEmpty || displayName.length < 3) {
      setState(() {
        _displayNameAvailable = null;
        _isCheckingDisplayName = false;
      });
      return;
    }

    // If same as current, it's available
    if (displayName.toLowerCase() == _profile?['displayName']?.toLowerCase()) {
      setState(() {
        _displayNameAvailable = true;
        _isCheckingDisplayName = false;
      });
      return;
    }

    setState(() => _isCheckingDisplayName = true);

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/consumer/auth/check-display-name?displayName=$displayName');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _displayNameAvailable = data['available'] == true;
          _isCheckingDisplayName = false;
        });
      }
    } catch (e) {
      setState(() {
        _displayNameAvailable = null;
        _isCheckingDisplayName = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_displayNameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is not available'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.patch('/consumer/profile', data: {
        'displayName': _displayNameController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _profile = data;
          _isEditing = false;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && _profile != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    // Reset to original values
                    _displayNameController.text = _profile!['displayName'] ?? '';
                    _nameController.text = _profile!['name'] ?? '';
                    _phoneController.text = _profile!['phone'] ?? '';
                    _displayNameAvailable = null;
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      // Edit mode
                      TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name (public)',
                          border: const OutlineInputBorder(),
                          prefixText: '@',
                          suffixIcon: _isCheckingDisplayName
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _displayNameAvailable == true
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : _displayNameAvailable == false
                                      ? const Icon(Icons.cancel, color: Colors.red)
                                      : null,
                          helperText: 'Letters, numbers, and underscores only',
                        ),
                        onChanged: (value) => _checkDisplayNameAvailability(value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name (private)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ] else ...[
                      // View mode
                      Text(
                        '@${_profile?['displayName'] ?? 'unknown'}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        _profile?['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Phone'),
                            subtitle: Text(_profile?['phone'] ?? 'Not set'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Member Since'),
                            subtitle: Text(_profile?['createdAt']?.toString().substring(0, 10) ?? 'Unknown'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.favorite),
                            title: const Text('Favorite Plants'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Recently Viewed'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final storage = RepositoryProvider.of<SecureStorage>(context);
                          await storage.clearAll();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
