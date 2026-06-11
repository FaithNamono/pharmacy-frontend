// lib/services/auth_service.dart

import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;
  
  AuthService(this._apiService, this._storageService);

  // LOGIN METHOD - handles nested response from ApiService
  Future<AuthResponse> login(String email, String password) async {
    try {
      print("🔐 LOGIN ATTEMPT: $email");
      
      final response = await _apiService.login(
        username: email,
        password: password,
      );
      
      print("📦 LOGIN RESPONSE: $response");

      // Check if the outer response was successful
      if (response['success'] == true) {
        // The actual data is inside response['data']
        final data = response['data'];
        
        if (data is Map<String, dynamic>) {
          // Check if login was successful in the nested response
          if (data['success'] == true) {
            // Extract token and user
            final String? token = data['token'];
            final Map<String, dynamic>? userData = data['user'];
            
            if (token != null && token.isNotEmpty) {
              await _storageService.saveToken(token);
            }
            
            if (userData != null) {
              // Convert Map to User object before saving
              final user = User.fromJson(userData);
              await _storageService.saveUser(user);
              
              return AuthResponse(
                isSuccess: true,
                user: user,
                token: token,
              );
            }
          }
          
          // Check for verification requirement
          if (data['requires_verification'] == true) {
            return AuthResponse(
              isSuccess: false,
              error: data['error'] ?? 'Verification required',
              requiresVerification: true,
              email: data['email'],
            );
          }
          
          // Handle error from nested response
          return AuthResponse(
            isSuccess: false,
            error: data['error'] ?? 'Login failed',
          );
        }
        
        return AuthResponse(
          isSuccess: false,
          error: 'Invalid response format',
        );
      } else {
        // Outer response failed (network error, etc.)
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      print("❌ LOGIN ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // REGISTER METHOD
  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    try {
      print("📝 REGISTER ATTEMPT: ${userData['email']}");
      
      final response = await _apiService.register(userData);
      
      print("📦 REGISTER RESPONSE: $response");
      
      if (response['success'] == true) {
        final data = response['data'];
        
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            User? user;
            if (data['user'] != null) {
              user = User.fromJson(data['user']);
            }
            
            return AuthResponse(
              isSuccess: true,
              user: user,
            );
          } else {
            return AuthResponse(
              isSuccess: false,
              error: data['error'] ?? 'Registration failed',
            );
          }
        }
        
        return AuthResponse(
          isSuccess: true,
        );
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      print("❌ REGISTER ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // SEND OTP METHOD
  Future<AuthResponse> sendOtp({
    String? email,
    String? phone,
    required String otpType,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'otp_type': otpType,
      };
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      
      print("📧 SEND OTP DATA: $body");
      
      final response = await _apiService.post('/api/auth/send-otp/', body);
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Failed to send OTP',
            );
          }
        }
        
        return AuthResponse(isSuccess: true);
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      print("❌ SEND OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // VERIFY OTP METHOD
  Future<AuthResponse> verifyOtp({
    String? email,
    String? phone,
    required String otp,
    required String otpType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'otp': otp,
        'otp_type': otpType,
      };
      
      if (otpType == 'email' && email != null) {
        data['email'] = email;
      } else if (otpType == 'phone' && phone != null) {
        data['phone'] = phone;
      }
      
      print("🔐 VERIFY OTP DATA: $data");
      
      final response = await _apiService.post('/api/auth/verify-otp/', data);
      
      print("📦 VERIFY OTP RESPONSE: $response");
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Invalid OTP',
            );
          }
        }
        
        return AuthResponse(isSuccess: true);
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      print("❌ VERIFY OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // FORGOT PASSWORD METHOD
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/api/auth/forgot-password/', {
        'email': email,
      });
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Failed to send reset instructions',
            );
          }
        }
        
        return AuthResponse(isSuccess: true);
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Failed to send reset instructions',
        );
      }
    } catch (e) {
      print("❌ FORGOT PASSWORD ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // RESET PASSWORD WITH OTP METHOD
  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    try {
      final response = await _apiService.post('/api/auth/reset-password/', {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
        'confirm_password': newPassword,
      });
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          return responseData['success'] == true;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("❌ RESET PASSWORD ERROR: $e");
      return false;
    }
  }

  // ============================================================
  // USER PROFILE UPDATE METHODS
  // ============================================================

  // UPDATE USERNAME
  Future<bool> updateUsername(int userId, String newUsername) async {
    try {
      final response = await _apiService.put('/api/users/$userId/username', {
        'username': newUsername,
      });
      
      print("📝 UPDATE USERNAME RESPONSE: $response");
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] == true;
          
          if (success) {
            // Update stored user
            final currentUser = await _storageService.getUser();
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(username: newUsername);
              await _storageService.saveUser(updatedUser);
            }
          }
          
          return success;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("❌ UPDATE USERNAME ERROR: $e");
      return false;
    }
  }

  // UPDATE EMAIL
  Future<bool> updateEmail(int userId, String newEmail) async {
    try {
      final response = await _apiService.put('/api/users/$userId/email', {
        'email': newEmail,
      });
      
      print("📧 UPDATE EMAIL RESPONSE: $response");
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] == true;
          
          if (success) {
            // Update stored user
            final currentUser = await _storageService.getUser();
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(email: newEmail);
              await _storageService.saveUser(updatedUser);
            }
          }
          
          return success;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("❌ UPDATE EMAIL ERROR: $e");
      return false;
    }
  }

  // UPDATE PHONE
  Future<bool> updatePhone(int userId, String newPhone) async {
    try {
      final response = await _apiService.put('/api/users/$userId/phone', {
        'phone': newPhone,
      });
      
      print("📱 UPDATE PHONE RESPONSE: $response");
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] == true;
          
          if (success) {
            // Update stored user
            final currentUser = await _storageService.getUser();
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(phone: newPhone);
              await _storageService.saveUser(updatedUser);
            }
          }
          
          return success;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("❌ UPDATE PHONE ERROR: $e");
      return false;
    }
  }

  Future<bool> updatePassword(int userId, String currentPassword, String newPassword) async {
  try {
    // Use the correct endpoint - either /api/auth/change-password/ or /api/users/change-password/
    final response = await _apiService.post('/api/auth/change-password/', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': newPassword,
    });
    
    print("🔒 CHANGE PASSWORD RESPONSE: $response");
    
    if (response['success'] == true) {
      final responseData = response['data'];
      
      bool success = false;
      if (responseData is Map<String, dynamic>) {
        success = responseData['success'] == true;
      } else {
        success = true;
      }
      
      if (success) {
        final currentUser = await _storageService.getUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            lastPasswordChange: DateTime.now().toIso8601String(),
          );
          await _storageService.saveUser(updatedUser);
        }
      }
      
      return success;
    }
    
    print("❌ CHANGE PASSWORD FAILED: ${response['error']}");
    return false;
  } catch (e) {
    print("❌ CHANGE PASSWORD ERROR: $e");
    return false;
  }
}

  // ============================================================
  // USER PROFILE METHODS
  // ============================================================

  // GET CURRENT USER
  Future<User?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _apiService.post('/api/auth/logout/', {});
    } catch (e) {
      print("⚠️ Logout API error: $e");
    }
    
    await _storageService.clearUser();
    await _storageService.clearToken();
  }
}