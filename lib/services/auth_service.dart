import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ytx/services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(storageServiceProvider));
});

class AuthService {
  final StorageService _storage;
  static const String _baseUrl = 'https://shashwatidr-ytxauth.hf.space';

  AuthService(this._storage);

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    required String psqlUri,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'psql_uri': psqlUri,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      await _saveUserSession(user);
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      await _saveUserSession(user);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.clearUserSession();
  }

  Future<void> _saveUserSession(Map<String, dynamic> user) async {
    await _storage.setPostgresUri(user['psql_uri']);
    await _storage.setUserInfo(user['username'], user['email']);
  }
  
  bool get isLoggedIn => _storage.username != null;
}
