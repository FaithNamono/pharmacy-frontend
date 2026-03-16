import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';  // Add this
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/medicines/medicine_list_screen.dart';
import 'screens/medicines/add_medicine_screen.dart';
import 'screens/medicines/medicine_detail_screen.dart';
import 'screens/sales/sale_list_screen.dart';
import 'screens/sales/new_sale_screen.dart';
import 'screens/sales/sale_detail_screen.dart';
import 'screens/reports/report_dashboard.dart';
import 'screens/reports/sales_report_screen.dart';
import 'screens/reports/inventory_report_screen.dart';
import 'screens/reports/staff_report_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';  // Add this
import 'screens/settings/change_password_screen.dart';  // Add this
import 'screens/settings/about_screen.dart';  // Add this
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  const storage = FlutterSecureStorage();
  final storageService = StorageService(storage);
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);
  
  // Check if onboarding is completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  runApp(MyApp(
    apiService: apiService,
    authService: authService,
    storageService: storageService,
    onboardingCompleted: onboardingCompleted,
  ));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  final StorageService storageService;
  final bool onboardingCompleted;

  const MyApp({
    Key? key,
    required this.apiService,
    required this.authService,
    required this.storageService,
    required this.onboardingCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicineProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SaleProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(apiService),
        ),
        ChangeNotifierProvider(  // Add this
          create: (_) => SettingsProvider(storageService),
        ),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'CT Pharmacy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme, // You'll need to create this
            themeMode: settingsProvider.getThemeMode(),
            initialRoute: _getInitialRoute(authProvider, onboardingCompleted),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/medicines': (context) => const MedicineListScreen(),
              '/add-medicine': (context) => const AddMedicineScreen(),
              '/sales': (context) => const SaleListScreen(),
              '/new-sale': (context) => const NewSaleScreen(),
              '/reports': (context) => const ReportDashboard(),
              '/sales-report': (context) => const SalesReportScreen(),
              '/inventory-report': (context) => const InventoryReportScreen(),
              '/staff-report': (context) => const StaffReportScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),  // Add this
              '/change-password': (context) => const ChangePasswordScreen(),  // Add this
              '/about': (context) => const AboutScreen(),  // Add this
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/medicine-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => MedicineDetailScreen(medicineId: args['id']),
                );
              }
              if (settings.name == '/sale-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => SaleDetailScreen(saleId: args['id']),
                );
              }
              if (settings.name == '/otp-verification') {
                final email = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => OtpVerificationScreen(email: email),
                );
              }
              if (settings.name == '/reset-password') {
                final args = settings.arguments as Map<String, String>;
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    email: args['email'] ?? '',
                    otp: args['otp'],
                    uid: args['uid'],
                    token: args['token'],
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute(AuthProvider authProvider, bool onboardingCompleted) {
    if (authProvider.isLoading) {
      return '/splash';
    }
    
    if (authProvider.isAuthenticated) {
      return '/dashboard';
    }
    
    if (!onboardingCompleted) {
      return '/onboarding';
    }
    
    return '/login';
  }
}