import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class Owner {
  final String id;
  final String email;
  final String name;
  final String? phone;

  Owner({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
    );
  }
}

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<Owner> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _apiClient.post('/v1/owner/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
    });

    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['tokens']['accessToken'],
      refreshToken: data['tokens']['refreshToken'],
    );
    await _storage.saveUserId(data['owner']['id']);
    await _storage.saveUserType('owner');

    return Owner.fromJson(data['owner']);
  }

  Future<Owner> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/v1/owner/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['tokens']['accessToken'],
      refreshToken: data['tokens']['refreshToken'],
    );
    await _storage.saveUserId(data['owner']['id']);
    await _storage.saveUserType('owner');

    return Owner.fromJson(data['owner']);
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }

  Future<Owner?> getProfile() async {
    final response = await _apiClient.get('/v1/owner/profile');
    if (response.data['data'] != null) {
      return Owner.fromJson(response.data['data']);
    }
    return null;
  }
}
