import 'dart:convert';
import '../models/user.dart';
import '../models/auth_response.dart';  // Make sure this file exists
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userData = data['user'];
        
        await _storageService.saveToken(token);
        await _storageService.saveUser(userData);
        
        return AuthResponse(
          token: token,
          user: User.fromJson(userData),
        );
      }
      return AuthResponse(error: 'Invalid credentials');
    } catch (e) {
      return AuthResponse(error: 'Connection error. Please try again.');
    }
  }

  Future<bool> logout() async {
    try {
      await _apiService.logout();
      await _storageService.clearAll();
      return true;
    } catch (e) {
      await _storageService.clearAll();
      return false;
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.register(userData);
      
      if (response.statusCode == 201) {
        final data = response.data;
        return AuthResponse(
          message: data['message'],
          otp: data['otp']?.toString(),
        );
      } else if (response.statusCode == 400) {
        final errors = response.data;
        String errorMessage = '';
        errors.forEach((key, value) {
          errorMessage += '$key: ${value.join(', ')}\n';
        });
        return AuthResponse(error: errorMessage);
      }
      return AuthResponse(error: 'Registration failed');
    } catch (e) {
      return AuthResponse(error: 'Connection error. Please try again.');
    }
  }

  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiService.verifyOtp(email, otp);
      
      if (response.statusCode == 200) {
        return AuthResponse(message: response.data['message']);
      }
      return AuthResponse(error: 'Invalid OTP');
    } catch (e) {
      return AuthResponse(error: 'Verification failed');
    }
  }

  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      
      if (response.statusCode == 200) {
        final data = response.data;
        return AuthResponse(
          message: data['message'],
          otp: data['otp']?.toString(),
          uid: data['uid'],
          resetToken: data['token'],
        );
      }
      return AuthResponse(error: response.data['error'] ?? 'Failed to send reset email');
    } catch (e) {
      return AuthResponse(error: 'Connection error. Please try again.');
    }
  }

  Future<bool> resetPassword(String uid, String token, String newPassword) async {
    try {
      final response = await _apiService.resetPassword(uid, token, newPassword);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    try {
      final response = await _apiService.resetPasswordWithOtp(email, otp, newPassword);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await _apiService.resendOtp(email);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null;
  }
}