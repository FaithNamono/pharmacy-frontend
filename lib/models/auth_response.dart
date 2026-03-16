import 'user.dart';

class AuthResponse {
  final String? token;
  final User? user;
  final String? message;
  final String? error;
  final String? otp;
  final String? uid;
  final String? resetToken;

  AuthResponse({
    this.token,
    this.user,
    this.message,
    this.error,
    this.otp,
    this.uid,
    this.resetToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      message: json['message'],
      error: json['error'],
      otp: json['otp']?.toString(),
      uid: json['uid'],
      resetToken: json['token'],
    );
  }

  bool get isSuccess => token != null || message != null;
}