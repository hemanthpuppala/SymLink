import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class Consumer {
  final String id;
  final String email;
  final String name;
  final String? phone;

  Consumer({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
  });

  factory Consumer.fromJson(Map<String, dynamic> json) {
    return Consumer(
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

  Future<Consumer> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _apiClient.post('/v1/consumer/auth/register', data: {
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
    await _storage.saveUserId(data['consumer']['id']);
    await _storage.saveUserType('consumer');

    return Consumer.fromJson(data['consumer']);
  }

  Future<Consumer> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/v1/consumer/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data['data'];
    await _storage.saveTokens(
      accessToken: data['tokens']['accessToken'],
      refreshToken: data['tokens']['refreshToken'],
    );
    await _storage.saveUserId(data['consumer']['id']);
    await _storage.saveUserType('consumer');

    return Consumer.fromJson(data['consumer']);
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
