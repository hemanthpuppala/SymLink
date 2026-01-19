import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../plant_profile/repositories/plant_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Plant> _plants = [];
  int _unreadMessages = 0;
  bool _isLoading = true;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupListeners();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    // Listen for new messages to update badge
    _messageSub = SyncService.instance.onNewMessage.listen((_) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadPlants(),
      _loadUnreadCount(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPlants() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/owner/plant');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          setState(() {
            _plants = data.map((json) => Plant.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print('[Dashboard] Error loading plants: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/owner/conversations/unread-count');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _unreadMessages = data['count'] ?? 0;
        });
      }
    } catch (e) {
      print('[Dashboard] Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowGrid Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildQuickStats(context),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    Text(
                      'My Plants',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _plants.isEmpty
                        ? _buildPlantsPlaceholder(context)
                        : _buildPlantsList(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final verifiedCount = _plants.where((p) => p.isVerified).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.water_drop,
              label: 'Plants',
              value: _plants.length.toString(),
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.verified,
              label: 'Verified',
              value: verifiedCount.toString(),
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.message,
              label: 'Messages',
              value: _unreadMessages.toString(),
              showBadge: _unreadMessages > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline,
            label: 'Add Plant',
            onTap: () => context.push('/plants/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.verified_user_outlined,
            label: 'Verification',
            onTap: () => context.push('/verification'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.chat_outlined,
            label: 'Messages',
            onTap: () => context.push('/chat'),
            badgeCount: _unreadMessages,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantsPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No plants yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first water plant to get started',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/plants/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Plant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantsList(BuildContext context) {
    return Column(
      children: _plants.map((plant) => _PlantCard(plant: plant)).toList(),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;

  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: plant.isVerified ? Colors.green : Colors.grey,
          child: const Icon(Icons.water_drop, color: Colors.white),
        ),
        title: Text(plant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: plant.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    plant.isActive ? 'Open' : 'Closed',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                if (plant.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/plants/${plant.id}'),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showBadge;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            if (showBadge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: Colors.blue, size: 32),
                  if (badgeCount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
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
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
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
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
