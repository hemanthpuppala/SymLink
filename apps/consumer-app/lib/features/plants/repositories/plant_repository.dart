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
  final double? distance;
  final PlantOwner? owner;

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
    this.distance,
    this.owner,
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
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      owner: json['owner'] != null
          ? PlantOwner.fromJson(json['owner'])
          : null,
    );
  }
}

class PlantOwner {
  final String id;
  final String name;

  PlantOwner({
    required this.id,
    required this.name,
  });

  factory PlantOwner.fromJson(Map<String, dynamic> json) {
    return PlantOwner(
      id: json['id'],
      name: json['name'],
    );
  }
}

class PlantRepository {
  final ApiClient _apiClient;

  PlantRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Plant>> getNearbyPlants({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/v1/consumer/plants/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'limit': limit,
      },
    );

    final data = response.data['data'];
    if (data is List) {
      return data.map((json) => Plant.fromJson(json)).toList();
    }
    return [];
  }

  Future<PlantSearchResult> searchPlants({
    String? query,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (query != null && query.isNotEmpty) {
      params['query'] = query;
    }
    if (latitude != null) {
      params['latitude'] = latitude;
    }
    if (longitude != null) {
      params['longitude'] = longitude;
    }

    final response = await _apiClient.get(
      '/v1/consumer/plants/search',
      queryParameters: params,
    );

    final data = response.data['data'];
    final plants = (data['plants'] as List)
        .map((json) => Plant.fromJson(json))
        .toList();

    final meta = data['meta'];
    return PlantSearchResult(
      plants: plants,
      page: meta['page'],
      limit: meta['limit'],
      total: meta['total'],
      totalPages: meta['totalPages'],
    );
  }

  Future<Plant> getPlantDetails(String id) async {
    final response = await _apiClient.get('/v1/consumer/plants/$id');
    return Plant.fromJson(response.data['data']);
  }
}

class PlantSearchResult {
  final List<Plant> plants;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PlantSearchResult({
    required this.plants,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}
