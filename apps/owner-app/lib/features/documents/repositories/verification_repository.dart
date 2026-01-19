import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class VerificationRequest {
  final String id;
  final String status;
  final List<String> documents;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final PlantInfo plant;
  final ReviewerInfo? reviewer;

  VerificationRequest({
    required this.id,
    required this.status,
    required this.documents,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    required this.plant,
    this.reviewer,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'],
      status: json['status'],
      documents: List<String>.from(json['documents'] ?? []),
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      plant: PlantInfo.fromJson(json['plant']),
      reviewer: json['reviewer'] != null
          ? ReviewerInfo.fromJson(json['reviewer'])
          : null,
    );
  }
}

class PlantInfo {
  final String id;
  final String name;
  final String address;

  PlantInfo({
    required this.id,
    required this.name,
    required this.address,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      id: json['id'],
      name: json['name'],
      address: json['address'],
    );
  }
}

class ReviewerInfo {
  final String id;
  final String name;

  ReviewerInfo({
    required this.id,
    required this.name,
  });

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      id: json['id'],
      name: json['name'],
    );
  }
}

class VerificationRepository {
  final ApiClient _apiClient;

  VerificationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<VerificationRequest>> getVerificationRequests() async {
    final response = await _apiClient.get('/v1/owner/verification');
    final data = response.data['data'];
    if (data is List) {
      return data.map((json) => VerificationRequest.fromJson(json)).toList();
    }
    return [];
  }

  Future<VerificationRequest> getVerificationRequest(String id) async {
    final response = await _apiClient.get('/v1/owner/verification/$id');
    return VerificationRequest.fromJson(response.data['data']);
  }

  Future<VerificationRequest> submitVerification({
    required String plantId,
    required List<File> documents,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'plantId': plantId,
      if (notes != null) 'notes': notes,
      'documents': await Future.wait(
        documents.map((file) => MultipartFile.fromFile(file.path)),
      ),
    });

    final response = await _apiClient.post(
      '/v1/owner/verification',
      data: formData,
    );
    return VerificationRequest.fromJson(response.data['data']);
  }
}
