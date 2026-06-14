import 'package:flutter/material.dart';

class AppColors {
  // Logo Brand Colors
  static const Color primaryGreen = Color(0xFF247647);
  static const Color primaryLight = Color(0xFFE4F2EA);
  static const Color primaryDark = Color(0xFF1B5A35);
  static const Color veryLightGreen = Color(0xFFF4FAF6);

  // Logo Navy Accent
  static const Color logoNavy = Color(0xFF31354A);

  // Accent Colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF44336);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color darkText = logoNavy;
  static const Color mediumText = Color(0xFF4A5568);
  static const Color lightText = Color(0xFF718096);

  static const Color darkGrey = Color(0xFF616161);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Status Colors
  static const Color success = primaryGreen;
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Gradient
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryGreen,
      Color(0xFF2E8B57),
    ],
  );
}

class AppStrings {
  static const String appName = 'CT Pharmacy';
  static const String fullName = 'CT Pharmacy Management System';
  static const String tagline = 'Your Trusted Pharmacy Partner';
  static const String welcome = 'Welcome to CT Pharmacy';
  static const String loading = 'Loading...';

  static const String dashboard = 'Dashboard';
  static const String medicines = 'Medicines';
  static const String sales = 'Sales';
  static const String reports = 'Reports';
  static const String profile = 'Profile';
  static const String settings = 'Settings';

  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String refresh = 'Refresh';
}

class AppDurations {
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
}

class StorageKeys {
  static const String firstLaunch = 'first_launch';
  static const String token = 'auth_token';
  static const String user = 'user_data';
  static const String theme = 'theme_mode';
}

class AppConstants {
  static const String baseUrl = 'http://localhost:8000/api';

  static const String loginEndpoint = '/auth/login/';
  static const String logoutEndpoint = '/auth/logout/';
  static const String registerEndpoint = '/auth/register/';
  static const String verifyOtpEndpoint = '/auth/verify-otp/';
  static const String forgotPasswordEndpoint = '/auth/forgot-password/';
  static const String resetPasswordEndpoint = '/auth/reset-password/';
  static const String resetPasswordOtpEndpoint = '/auth/reset-password-otp/';
  static const String resendOtpEndpoint = '/auth/resend-otp/';
  static const String usersEndpoint = '/auth/users/';
  static const String medicinesEndpoint = '/medicines/';
  static const String categoriesEndpoint = '/medicines/categories/';
  static const String suppliersEndpoint = '/medicines/suppliers/';
  static const String salesEndpoint = '/sales/';
  static const String reportsEndpoint = '/reports/';

  static const String tokenKey = StorageKeys.token;
  static const String userKey = StorageKeys.user;
  static const String themeKey = StorageKeys.theme;

  static const double paddingSmallest = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  static const double paddingHuge = 48.0;

  static const double fontSizeTiny = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 18.0;
  static const double fontSizeHeading = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeDisplay = 32.0;

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusExtraLarge = 16.0;
  static const double radiusCircular = 100.0;

  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  static const Color primaryColor = AppColors.primaryGreen;
}