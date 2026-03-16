import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService(this._storage);

  // Token methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // User methods
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: AppConstants.userKey, value: json.encode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userString = await _storage.read(key: AppConstants.userKey);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  // Theme methods
  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: AppConstants.themeKey, value: themeMode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: AppConstants.themeKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}