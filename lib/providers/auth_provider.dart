// lib/providers/auth_provider.dart

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
  String? _verificationEmail;
  String? _verificationPhone;
  String? _pendingEmail;
  String? _pendingPhone;

  AuthProvider(this._authService, this._storageService) {
    _loadUser();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get verificationEmail => _verificationEmail;
  String? get verificationPhone => _verificationPhone;
  String? get pendingEmail => _pendingEmail;
  String? get pendingPhone => _pendingPhone;

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUser() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);

      if (response.isSuccess && response.user != null) {
        _currentUser = response.user;
        _verificationEmail = null;
        _verificationPhone = null;
        
        // Save token if present
        if (response.token != null) {
          await _storageService.saveToken(response.token!);
        }
        
        _setLoading(false);
        return true;
      }

      // Verification required
      if (response.requiresVerification == true) {
        _verificationEmail = response.email;
        _error = response.error;
        _setLoading(false);
        return false;
      }

      // Login failed
      _error = response.error ?? 'Login failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(userData);

      if (response.isSuccess) {
        _verificationEmail = userData['email'];
        _setLoading(false);
        return true;
      } else {
        _error = response.error ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<bool> sendVerificationOtp(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.sendOtp(
        email: email,
        otpType: 'email',
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);
      return response.isSuccess;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPhoneVerificationOtp(String phone) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.sendOtp(
        phone: phone,
        otpType: 'phone',
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);
      return response.isSuccess;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp(
    String destination,
    String otp, {
    required String otpType,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyOtp(
        email: otpType == 'email' ? destination : null,
        phone: otpType == 'phone' ? destination : null,
        otp: otp,
        otpType: otpType,
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);
      return response.isSuccess;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email);

      if (response.isSuccess) {
        _verificationEmail = email;
        _setLoading(false);
        return true;
      } else {
        _error = response.error;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.resetPasswordWithOtp(
        email,
        otp,
        newPassword,
      );

      if (!success) {
        _error = 'Password reset failed';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // USER PROFILE UPDATE METHODS
  // ============================================================

  // UPDATE USERNAME
  Future<bool> updateUsername(String newUsername) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null) {
        _error = 'No user logged in';
        _setLoading(false);
        return false;
      }

      if (newUsername.length < 3) {
        _error = 'Username must be at least 3 characters';
        _setLoading(false);
        return false;
      }

      final success = await _authService.updateUsername(_currentUser!.id, newUsername);
      
      if (success) {
        _currentUser = _currentUser!.copyWith(username: newUsername);
        await _storageService.saveUser(_currentUser!);
        _setLoading(false);
        return true;
      } else {
        _error = 'Username already taken or invalid';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // UPDATE EMAIL - Step 1: Request OTP
  Future<bool> requestEmailUpdate(String newEmail) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null) {
        _error = 'No user logged in';
        _setLoading(false);
        return false;
      }

      if (!newEmail.contains('@') || !newEmail.contains('.')) {
        _error = 'Please enter a valid email address';
        _setLoading(false);
        return false;
      }

      // Send verification code to new email
      final response = await _authService.sendOtp(
        email: newEmail,
        otpType: 'email_update',
      );
      
      if (response.isSuccess) {
        _pendingEmail = newEmail;
        _setLoading(false);
        return true;
      } else {
        _error = response.error ?? 'Failed to send verification code';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // UPDATE EMAIL - Step 2: Verify OTP and complete update
  Future<bool> completeEmailUpdate(String otp) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null || _pendingEmail == null) {
        _error = 'Invalid operation';
        _setLoading(false);
        return false;
      }

      // Verify OTP
      final verifyResponse = await _authService.verifyOtp(
        email: _pendingEmail,
        otp: otp,
        otpType: 'email_update',
      );

      if (!verifyResponse.isSuccess) {
        _error = 'Invalid verification code';
        _setLoading(false);
        return false;
      }

      // Update email
      final success = await _authService.updateEmail(_currentUser!.id, _pendingEmail!);
      
      if (success) {
        _currentUser = _currentUser!.copyWith(email: _pendingEmail!);
        await _storageService.saveUser(_currentUser!);
        _pendingEmail = null;
        _setLoading(false);
        return true;
      } else {
        _error = 'Failed to update email';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // UPDATE PHONE - Step 1: Request OTP
  Future<bool> requestPhoneUpdate(String newPhone) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null) {
        _error = 'No user logged in';
        _setLoading(false);
        return false;
      }

      if (newPhone.length < 10) {
        _error = 'Please enter a valid phone number';
        _setLoading(false);
        return false;
      }

      // Send verification code to new phone
      final response = await _authService.sendOtp(
        phone: newPhone,
        otpType: 'phone_update',
      );
      
      if (response.isSuccess) {
        _pendingPhone = newPhone;
        _setLoading(false);
        return true;
      } else {
        _error = response.error ?? 'Failed to send verification code';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // UPDATE PHONE - Step 2: Verify OTP and complete update
  Future<bool> completePhoneUpdate(String otp) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null || _pendingPhone == null) {
        _error = 'Invalid operation';
        _setLoading(false);
        return false;
      }

      // Verify OTP
      final verifyResponse = await _authService.verifyOtp(
        phone: _pendingPhone,
        otp: otp,
        otpType: 'phone_update',
      );

      if (!verifyResponse.isSuccess) {
        _error = 'Invalid verification code';
        _setLoading(false);
        return false;
      }

      // Update phone
      final success = await _authService.updatePhone(_currentUser!.id, _pendingPhone!);
      
      if (success) {
        _currentUser = _currentUser!.copyWith(phone: _pendingPhone!);
        await _storageService.saveUser(_currentUser!);
        _pendingPhone = null;
        _setLoading(false);
        return true;
      } else {
        _error = 'Failed to update phone number';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
  _setLoading(true);
  _clearError();

  try {
    if (_currentUser == null) {
      _error = 'No user logged in';
      _setLoading(false);
      return false;
    }

    if (newPassword.length < 6) {
      _error = 'Password must be at least 6 characters';
      _setLoading(false);
      return false;
    }

    final success = await _authService.updatePassword(
      _currentUser!.id,
      currentPassword,
      newPassword,
    );
    
    if (success) {
      final now = DateTime.now().toIso8601String();
      _currentUser = _currentUser!.copyWith(lastPasswordChange: now);
      await _storageService.saveUser(_currentUser!);
      _setLoading(false);
      return true;
    } else {
      _error = 'Current password is incorrect or API error';
      _setLoading(false);
      return false;
    }
  } catch (e) {
    _error = e.toString();
    _setLoading(false);
    return false;
  }
}

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
      _currentUser = null;
      _verificationEmail = null;
      _verificationPhone = null;
      _pendingEmail = null;
      _pendingPhone = null;
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // ============================================================
  // CLEAR METHODS
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVerificationEmail() {
    _verificationEmail = null;
    notifyListeners();
  }

  void clearVerificationPhone() {
    _verificationPhone = null;
    notifyListeners();
  }

  void clearPendingEmail() {
    _pendingEmail = null;
    notifyListeners();
  }

  void clearPendingPhone() {
    _pendingPhone = null;
    notifyListeners();
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}