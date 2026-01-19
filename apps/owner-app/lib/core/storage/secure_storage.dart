import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userTypeKey = 'user_type';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
    ]);
    print('[SecureStorage] Tokens saved');
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_userIdKey);
  }

  Future<void> saveUserType(String userType) async {
    final prefs = await _prefs;
    await prefs.setString(_userTypeKey, userType);
  }

  Future<String?> getUserType() async {
    final prefs = await _prefs;
    return prefs.getString(_userTypeKey);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
