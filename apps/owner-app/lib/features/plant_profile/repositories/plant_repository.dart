import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Plant {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? description;
  final int? tdsLevel;
  final double? pricePerLiter;
  final String? operatingHours;
  final List<String> photos;
  final bool isVerified;
  final bool isActive;
  final VerificationRequest? latestVerification;

  Plant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.description,
    this.tdsLevel,
    this.pricePerLiter,
    this.operatingHours,
    required this.photos,
    required this.isVerified,
    required this.isActive,
    this.latestVerification,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'],
      description: json['description'],
      tdsLevel: json['tdsLevel'],
      pricePerLiter: json['pricePerLiter'] != null
          ? (json['pricePerLiter'] as num).toDouble()
          : null,
      operatingHours: json['operatingHours'],
      photos: List<String>.from(json['photos'] ?? []),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      latestVerification: json['verificationRequests'] != null &&
              (json['verificationRequests'] as List).isNotEmpty
          ? VerificationRequest.fromJson(json['verificationRequests'][0])
          : null,
    );
  }
}

class VerificationRequest {
  final String id;
  final String status;
  final List<String> documents;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;

  VerificationRequest({
    required this.id,
    required this.status,
    required this.documents,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'],
      status: json['status'],
      documents: List<String>.from(json['documents'] ?? []),
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PlantRepository {
  final ApiClient _apiClient;

  PlantRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Plant>> getMyPlants() async {
    final response = await _apiClient.get('/v1/owner/plant');
    final data = response.data['data'];
    if (data is List) {
      return data.map((json) => Plant.fromJson(json)).toList();
    }
    return [];
  }

  Future<Plant> getPlant(String id) async {
    final response = await _apiClient.get('/v1/owner/plant/$id');
    return Plant.fromJson(response.data['data']);
  }

  Future<Plant> createPlant({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? description,
    int? tdsLevel,
    double? pricePerLiter,
    String? operatingHours,
  }) async {
    final response = await _apiClient.post('/v1/owner/plant', data: {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (description != null) 'description': description,
      if (tdsLevel != null) 'tdsLevel': tdsLevel,
      if (pricePerLiter != null) 'pricePerLiter': pricePerLiter,
      if (operatingHours != null) 'operatingHours': operatingHours,
    });
    return Plant.fromJson(response.data['data']);
  }

  Future<Plant> updatePlant(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/v1/owner/plant/$id', data: updates);
    return Plant.fromJson(response.data['data']);
  }

  Future<Plant> updatePlantStatus(String id, bool isActive) async {
    final response = await _apiClient.patch(
      '/v1/owner/plant/$id/status',
      data: {'isActive': isActive},
    );
    return Plant.fromJson(response.data['data']);
  }

  Future<List<String>> uploadPhoto(String plantId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await _apiClient.post(
      '/v1/owner/plant/$plantId/photos',
      data: formData,
    );
    return List<String>.from(response.data['data']['photos'] ?? []);
  }

  Future<List<String>> deletePhoto(String plantId, int photoIndex) async {
    final response = await _apiClient.delete(
      '/v1/owner/plant/$plantId/photos/$photoIndex',
    );
    return List<String>.from(response.data['data']['photos'] ?? []);
  }
}
