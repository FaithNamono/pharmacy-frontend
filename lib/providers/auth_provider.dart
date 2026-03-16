import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService, this._storageService) {
    _loadUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.login(username, password);
    
    if (response.user != null) {
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.register(userData);
    
    if (response.isSuccess) {
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.verifyOtp(email, otp);
    
    _isLoading = false;
    notifyListeners();
    
    return response.isSuccess;
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.forgotPassword(email);
    
    _isLoading = false;
    notifyListeners();
    
    if (!response.isSuccess) {
      _error = response.error;
      return false;
    }
    return true;
  }

  Future<bool> resetPassword(String uid, String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.resetPassword(uid, token, newPassword);
    
    _isLoading = false;
    notifyListeners();
    
    if (!success) {
      _error = 'Password reset failed';
    }
    return success;
  }

  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.resetPasswordWithOtp(email, otp, newPassword);
    
    _isLoading = false;
    notifyListeners();
    
    if (!success) {
      _error = 'Password reset failed';
    }
    return success;
  }

  Future<bool> resendOtp(String email) async {
    return await _authService.resendOtp(email);
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}