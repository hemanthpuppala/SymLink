import 'package:equatable/equatable.dart';

enum DashboardStatus {
  initial,
  loading,
  loaded,
  error,
}

class PlantSummary extends Equatable {
  final String id;
  final String name;
  final String address;
  final bool isOpen;
  final String verificationStatus;
  final int? tdsReading;
  final double? pricePerLiter;
  final int viewCount;

  const PlantSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.verificationStatus,
    this.tdsReading,
    this.pricePerLiter,
    required this.viewCount,
  });

  factory PlantSummary.fromJson(Map<String, dynamic> json) {
    return PlantSummary(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      isOpen: json['isOpen'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'unverified',
      tdsReading: json['tdsReading'],
      pricePerLiter: json['pricePerLiter'] != null
          ? (json['pricePerLiter'] as num).toDouble()
          : null,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        isOpen,
        verificationStatus,
        tdsReading,
        pricePerLiter,
        viewCount,
      ];
}

class DashboardStats extends Equatable {
  final int totalViews;
  final int todayViews;
  final int weeklyViews;
  final int totalConversations;
  final int unreadMessages;

  const DashboardStats({
    this.totalViews = 0,
    this.todayViews = 0,
    this.weeklyViews = 0,
    this.totalConversations = 0,
    this.unreadMessages = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalViews: json['totalViews'] ?? 0,
      todayViews: json['todayViews'] ?? 0,
      weeklyViews: json['weeklyViews'] ?? 0,
      totalConversations: json['totalConversations'] ?? 0,
      unreadMessages: json['unreadMessages'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalViews,
        todayViews,
        weeklyViews,
        totalConversations,
        unreadMessages,
      ];
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final PlantSummary? plant;
  final DashboardStats stats;
  final String? error;
  final int unreadMessageCount;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.plant,
    this.stats = const DashboardStats(),
    this.error,
    this.unreadMessageCount = 0,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    PlantSummary? plant,
    DashboardStats? stats,
    String? error,
    int? unreadMessageCount,
  }) {
    return DashboardState(
      status: status ?? this.status,
      plant: plant ?? this.plant,
      stats: stats ?? this.stats,
      error: error,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }

  @override
  List<Object?> get props => [status, plant, stats, error, unreadMessageCount];
}
