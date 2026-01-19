import '../../core/api/api_client.dart';

class DailyViewCount {
  final String date;
  final int count;

  DailyViewCount({
    required this.date,
    required this.count,
  });

  factory DailyViewCount.fromJson(Map<String, dynamic> json) {
    return DailyViewCount(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

class Analytics {
  final int totalViews;
  final int weeklyViews;
  final List<DailyViewCount> dailyViews;
  final int uniqueViewers;
  final int weeklyUniqueViewers;

  Analytics({
    required this.totalViews,
    required this.weeklyViews,
    required this.dailyViews,
    required this.uniqueViewers,
    required this.weeklyUniqueViewers,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      totalViews: json['totalViews'] as int,
      weeklyViews: json['weeklyViews'] as int,
      dailyViews: (json['dailyViews'] as List)
          .map((e) => DailyViewCount.fromJson(e))
          .toList(),
      uniqueViewers: json['uniqueViewers'] as int,
      weeklyUniqueViewers: json['weeklyUniqueViewers'] as int,
    );
  }
}

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Analytics> getAnalytics() async {
    final response = await _apiClient.get('/v1/owner/analytics');
    return Analytics.fromJson(response.data['data']);
  }
}
