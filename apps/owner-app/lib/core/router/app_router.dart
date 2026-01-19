import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/plants',
            name: 'plants',
            builder: (context, state) => const PlantsListScreen(),
          ),
          GoRoute(
            path: '/plants/new',
            name: 'new-plant',
            builder: (context, state) => const PlantFormScreen(),
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
            path: '/plants/:id/edit',
            name: 'edit-plant',
            builder: (context, state) {
              final plantId = state.pathParameters['id']!;
              return PlantFormScreen(plantId: plantId);
            },
          ),
          GoRoute(
            path: '/verification',
            name: 'verification',
            builder: (context, state) => const VerificationScreen(),
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
      // User is already authenticated, initialize SyncService and go to dashboard
      print('[Splash] User authenticated, initializing SyncService');
      SyncService.instance.initialize(apiClient.baseUrl, token);
      if (mounted) {
        context.go('/dashboard');
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
              'FlowGrid Owner',
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
  final _emailController = TextEditingController(text: 'owner@example.com');
  final _passwordController = TextEditingController(text: 'owner123');
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

      final response = await apiClient.post('/owner/auth/login', data: {
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
          final accessToken = tokens['accessToken'];
          final refreshToken = tokens['refreshToken'];
          print('[Login] Saving tokens - access: ${accessToken?.substring(0, 20)}...');
          await storage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          // Verify tokens were saved
          final savedToken = await storage.getAccessToken();
          print('[Login] Verified saved token: ${savedToken != null ? savedToken.substring(0, 20) : 'null'}...');

          // Initialize sync service for real-time updates
          SyncService.instance.initialize(
            apiClient.baseUrl,
            accessToken,
          );
        } else {
          print('[Login] No tokens in response!');
        }

        if (mounted) {
          context.go('/dashboard');
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
      appBar: AppBar(title: const Text('Owner Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 64, color: Colors.green),
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
      final response = await apiClient.get('/owner/conversations');

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
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Plants'),
          BottomNavigationBarItem(icon: _buildChatIcon(), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/plants');
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _plants = [];
  bool _isLoading = true;
  StreamSubscription? _plantSub;
  StreamSubscription? _verificationSub;

  @override
  void initState() {
    super.initState();
    _ensureSyncConnected();
    _loadData();
    _setupSyncListeners();
  }

  @override
  void dispose() {
    _plantSub?.cancel();
    _verificationSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureSyncConnected() async {
    if (!SyncService.instance.isConnected) {
      final storage = RepositoryProvider.of<SecureStorage>(context);
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final token = await storage.getAccessToken();
      if (token != null) {
        print('[Dashboard] Initializing SyncService');
        SyncService.instance.initialize(apiClient.baseUrl, token);
      }
    }
  }

  void _setupSyncListeners() {
    // Listen for plant changes
    _plantSub = SyncService.instance.onPlantUpdated.listen((_) {
      _loadData();
    });

    // Listen for verification updates
    _verificationSub = SyncService.instance.onVerificationUpdated.listen((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final plantsResponse = await apiClient.get('/owner/plant');

      if (plantsResponse.statusCode == 200) {
        setState(() {
          _plants = plantsResponse.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _plants.where((p) => p['isVerified'] == true).length;
    final activeCount = _plants.where((p) => p['isActive'] == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Total Plants', value: '${_plants.length}', icon: Icons.water_drop, color: Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(title: 'Verified', value: '$verifiedCount', icon: Icons.verified, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Active', value: '$activeCount', icon: Icons.check_circle, color: Colors.teal)),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(title: 'Pending', value: '${_plants.length - verifiedCount}', icon: Icons.pending, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Plants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(onPressed: () => context.go('/plants'), child: const Text('View All')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_plants.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.add_business, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No plants yet'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => context.go('/plants/new'),
                                child: const Text('Add Your First Plant'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_plants.take(3).map((plant) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: plant['isVerified'] == true ? Colors.green : Colors.grey,
                            child: const Icon(Icons.water_drop, color: Colors.white),
                          ),
                          title: Text(plant['name'] ?? 'Unknown'),
                          subtitle: Text(plant['address'] ?? ''),
                          trailing: Chip(
                            label: Text(plant['isVerified'] == true ? 'Verified' : 'Pending'),
                            backgroundColor: plant['isVerified'] == true ? Colors.green.shade100 : Colors.orange.shade100,
                          ),
                          onTap: () => context.go('/plants/${plant['id']}'),
                        ),
                      ))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/plants/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Plant'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class PlantsListScreen extends StatefulWidget {
  const PlantsListScreen({super.key});

  @override
  State<PlantsListScreen> createState() => _PlantsListScreenState();
}

class _PlantsListScreenState extends State<PlantsListScreen> {
  List<dynamic> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/owner/plant');

      if (response.statusCode == 200) {
        setState(() {
          _plants = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/plants/new'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No plants added yet'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/plants/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Plant'),
                      ),
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
                        margin: const EdgeInsets.only(bottom: 12),
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
                                  Chip(
                                    label: Text(plant['isVerified'] == true ? 'Verified' : 'Pending', style: const TextStyle(fontSize: 10)),
                                    backgroundColor: plant['isVerified'] == true ? Colors.green.shade100 : Colors.orange.shade100,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(plant['isActive'] == true ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 10)),
                                    backgroundColor: plant['isActive'] == true ? Colors.blue.shade100 : Colors.grey.shade200,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'verify', child: Text('Request Verification')),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') context.go('/plants/${plant['id']}/edit');
                              if (value == 'verify') context.go('/verification');
                            },
                          ),
                          onTap: () => context.go('/plants/${plant['id']}'),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/plants/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PlantFormScreen extends StatefulWidget {
  final String? plantId;

  const PlantFormScreen({super.key, this.plantId});

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tdsController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();
  bool _isLoading = false;
  bool _isActive = true;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _tdsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.orange),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Move map to current location
      _mapController.move(LatLng(position.latitude, position.longitude), 15);

      // Reverse geocode to get address
      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    print('[PlantForm] Map tapped at: ${point.latitude}, ${point.longitude}');
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
    });
    // Reverse geocode to get address
    _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
        },
        options: Options(
          headers: {
            'User-Agent': 'FlowGridOwnerApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final address = response.data['display_name'] as String?;
        if (address != null && mounted) {
          setState(() {
            _addressController.text = address;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated from map!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('[PlantForm] Reverse geocode error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location selected: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);

      // Build data - only include optional fields if they have values
      final data = <String, dynamic>{
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (_descriptionController.text.isNotEmpty) {
        data['description'] = _descriptionController.text;
      }

      final tds = int.tryParse(_tdsController.text);
      if (tds != null) {
        data['tdsLevel'] = tds;
      }

      final price = double.tryParse(_priceController.text);
      if (price != null) {
        data['pricePerLiter'] = price;
      }

      final response = widget.plantId != null
          ? await apiClient.patch('/owner/plant/${widget.plantId}', data: data)
          : await apiClient.post('/owner/plant', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.plantId != null ? 'Plant updated!' : 'Plant created!')),
          );
          context.go('/plants');
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException && e.response != null) {
        print('[PlantForm] Error response: ${e.response?.data}');
        errorMsg = e.response?.data?['message']?.toString() ?? e.response?.data?.toString() ?? e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMsg'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.plantId != null ? 'Edit Plant' : 'Add New Plant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Plant Name *', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Location Section
              const Text('Location *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: const Text('Use My Location'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Selected: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                  ),
                ),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude ?? 17.385, _longitude ?? 78.4867), // Default to Hyderabad
                      initialZoom: 13,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'io.flowgrid.owner_app',
                      ),
                      if (_latitude != null && _longitude != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_latitude!, _longitude!),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('Tap on the map to select location', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tdsController,
                      decoration: const InputDecoration(labelText: 'TDS (ppm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price/Liter (₹)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Plant is Active'),
                subtitle: const Text('Consumers can see active plants'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlant,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.plantId != null ? 'Update Plant' : 'Create Plant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlantDetailsScreen extends StatelessWidget {
  final String plantId;

  const PlantDetailsScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Plant Details: $plantId'));
  }
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<dynamic> _plants = [];
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _selectedPlantId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final [plantsRes, requestsRes] = await Future.wait([
        apiClient.get('/owner/plant'),
        apiClient.get('/owner/verification'),
      ]);

      final requests = requestsRes.data['data'] ?? requestsRes.data ?? [];
      // Get plant IDs that already have pending verification requests
      final pendingPlantIds = (requests as List)
          .where((r) => r['status'] == 'PENDING')
          .map((r) => r['plant']?['id'] ?? r['plantId'])
          .toSet();

      setState(() {
        // Filter out verified plants AND plants with pending requests
        _plants = (plantsRes.data['data'] ?? [])
            .where((p) => p['isVerified'] != true && !pendingPlantIds.contains(p['id']))
            .toList();
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedPlantId == null) return;

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);

      // Use the simple endpoint (JSON body, no file uploads)
      await apiClient.post('/owner/verification/simple', data: {
        'plantId': _selectedPlantId,
        'notes': 'Verification request from mobile app',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request submitted!'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to submit verification request';
        if (e.toString().contains('already exists')) {
          message = 'A pending verification request already exists for this plant';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        _loadData(); // Refresh to update the list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Plants Needing Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_plants.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
                              const SizedBox(height: 8),
                              const Text('No plants need verification', textAlign: TextAlign.center),
                              const SizedBox(height: 4),
                              Text(
                                'All your plants are either verified or have pending requests.',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_plants.map((plant) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: _selectedPlantId == plant['id'] ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: Radio<String>(
                            value: plant['id'],
                            groupValue: _selectedPlantId,
                            onChanged: (v) => setState(() => _selectedPlantId = v),
                          ),
                          title: Text(plant['name'] ?? 'Unknown'),
                          subtitle: Text(plant['address'] ?? ''),
                          trailing: Chip(
                            label: const Text('Pending', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.orange.shade100,
                          ),
                          onTap: () => setState(() => _selectedPlantId = plant['id']),
                        ),
                      ))),
                    if (_plants.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedPlantId == null ? null : _submitVerification,
                          icon: const Icon(Icons.send),
                          label: const Text('Request Verification'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Text('Verification Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_requests.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              const Text('No verification requests yet'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_requests.map((req) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            req['status'] == 'APPROVED' ? Icons.check_circle :
                            req['status'] == 'REJECTED' ? Icons.cancel : Icons.pending,
                            color: req['status'] == 'APPROVED' ? Colors.green :
                                   req['status'] == 'REJECTED' ? Colors.red : Colors.orange,
                          ),
                          title: Text(req['plant']?['name'] ?? 'Unknown Plant'),
                          subtitle: Text('Status: ${req['status']}'),
                          trailing: Text(req['createdAt']?.substring(0, 10) ?? ''),
                        ),
                      ))),
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
      final response = await apiClient.get('/owner/conversations');

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
        title: const Text('Customer Messages'),
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
                            'No messages yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customer messages will appear here',
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
                              backgroundColor: Colors.green.shade100,
                              child: Icon(Icons.person, color: Colors.green.shade700),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv['otherPartyName'] ?? 'Customer',
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
                                      color: unreadCount > 0 ? Colors.green : Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv['plantName'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg != null
                                            ? '${lastMsg['senderType'] == 'owner' ? 'You: ' : ''}${lastMsg['content']}'
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
                                          color: Colors.green,
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
                              ],
                            ),
                            isThreeLine: true,
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
      if (mounted && data['userType'] != 'owner') {
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

      // Load messages
      final response = await apiClient.get('/owner/conversations/${widget.conversationId}/messages');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _messages = data['messages'] ?? [];
          _conversation = data['conversation'];
          _isLoading = false;
        });

        // Mark as read
        await apiClient.post('/owner/conversations/${widget.conversationId}/read');

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
        '/owner/conversations/${widget.conversationId}/messages',
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
    if (message['senderType'] != 'owner') return const SizedBox.shrink();

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
    final customerName = _conversation?['otherPartyName'] ?? 'Customer';
    final plantName = _conversation?['plantName'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerName, style: const TextStyle(fontSize: 18)),
            if (_otherTyping)
              const Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            else if (plantName != null)
              Text(
                plantName,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                            const Text('Start the conversation!'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderType'] == 'owner';

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
                                color: isMe ? Colors.green : Colors.grey.shade200,
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
                      backgroundColor: Colors.green,
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/owner/profile');

      if (response.statusCode == 200) {
        setState(() {
          _profile = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final storage = RepositoryProvider.of<SecureStorage>(context);
    await storage.clearAll();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile?['name'] ?? 'Owner',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(_profile?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
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
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(_profile?['email'] ?? 'Not set'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Member Since'),
                          subtitle: Text(_profile?['createdAt']?.substring(0, 10) ?? 'Unknown'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.verified_user),
                          title: const Text('Verification'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/verification'),
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
                      onPressed: _logout,
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
    );
  }
}
