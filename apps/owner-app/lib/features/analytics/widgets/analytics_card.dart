import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../analytics_repository.dart';
import '../../../core/api/api_client.dart';

class AnalyticsCard extends StatefulWidget {
  final VoidCallback? onTap;

  const AnalyticsCard({super.key, this.onTap});

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  Analytics? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final repository = AnalyticsRepository(apiClient: apiClient);
      final analytics = await repository.getAnalytics();

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_analytics == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No analytics data')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Total Views',
                value: _analytics!.totalViews.toString(),
                icon: Icons.visibility,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'This Week',
                value: _analytics!.weeklyViews.toString(),
                icon: Icons.trending_up,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Unique',
                value: _analytics!.uniqueViewers.toString(),
                icon: Icons.people,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: _buildMiniChart(),
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    if (_analytics == null || _analytics!.dailyViews.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = _analytics!.dailyViews
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _analytics!.dailyViews.map((daily) {
        final height = maxCount > 0 ? (daily.count / maxCount) * 50 : 0.0;
        final dayLabel = daily.date.split('-').last;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height.clamp(4.0, 50.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
