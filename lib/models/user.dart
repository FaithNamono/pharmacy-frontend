// lib/models/user.dart
import 'dart:convert';

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? role;
  final bool isEmailVerified;
  final bool isAdmin;
  final bool isActive;
  final String? address;
  final String? lastPasswordChange;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.role,
    this.isEmailVerified = false,
    this.isAdmin = false,
    this.isActive = true,
    this.address,
    this.lastPasswordChange,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      role: json['role'],
      isEmailVerified: json['is_email_verified'] ?? false,
      isAdmin: json['is_admin'] ?? json['role'] == 'admin',
      isActive: json['is_active'] ?? true,
      address: json['address'],
      lastPasswordChange: json['last_password_change'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role,
      'is_email_verified': isEmailVerified,
      'is_admin': isAdmin,
      'is_active': isActive,
      'address': address,
      'last_password_change': lastPasswordChange,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory User.fromJsonString(String str) => User.fromJson(jsonDecode(str));

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
    bool? isEmailVerified,
    bool? isAdmin,
    bool? isActive,
    String? address,
    String? lastPasswordChange,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
    );
  }
}