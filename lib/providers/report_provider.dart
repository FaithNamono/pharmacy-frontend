import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  Map<String, dynamic>? _dashboardSummary;
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _inventoryReport;
  Map<String, dynamic>? _staffReport;
  List<dynamic> _dailySalesReport = [];
  List<dynamic> _lowStockReport = [];
  List<dynamic> _expiredReport = [];
  
  bool _isLoading = false;
  String? _error;

  ReportProvider(this._apiService);

  // Getters
  Map<String, dynamic>? get dashboardSummary => _dashboardSummary;
  Map<String, dynamic>? get salesReport => _salesReport;
  Map<String, dynamic>? get inventoryReport => _inventoryReport;
  Map<String, dynamic>? get staffReport => _staffReport;
  List<dynamic> get dailySalesReport => _dailySalesReport;
  List<dynamic> get lowStockReport => _lowStockReport;
  List<dynamic> get expiredReport => _expiredReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load dashboard summary
  Future<void> loadDashboardSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getDashboardSummary();
      _dashboardSummary = _parseResponseData(response.data);
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard summary: $e';
      print('Error loading dashboard: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load sales report
  Future<void> loadSalesReport({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      _salesReport = _parseResponseData(response.data);
      _error = null;
    } catch (e) {
      _error = 'Failed to load sales report: $e';
      print('Error loading sales report: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load inventory report
  Future<void> loadInventoryReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getInventoryReport();
      _inventoryReport = _parseResponseData(response.data);
      _error = null;
    } catch (e) {
      _error = 'Failed to load inventory report: $e';
      print('Error loading inventory report: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load staff report
  Future<void> loadStaffReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getStaffReport();
      _staffReport = _parseResponseData(response.data);
      _error = null;
    } catch (e) {
      _error = 'Failed to load staff report: $e';
      print('Error loading staff report: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load daily sales report
  Future<void> loadDailySalesReport() async {
    try {
      final response = await _apiService.getDailySalesReport();
      final data = response.data;
      
      if (data is Map && data['sales'] != null) {
        _dailySalesReport = data['sales'] is List ? data['sales'] : [];
      } else if (data is List) {
        _dailySalesReport = data;
      } else {
        _dailySalesReport = [];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading daily sales report: $e');
    }
  }

  // Load low stock report
  Future<void> loadLowStockReport() async {
    try {
      final response = await _apiService.getLowStockReport();
      final data = response.data;
      
      if (data is Map && data['medicines'] != null) {
        _lowStockReport = data['medicines'] is List ? data['medicines'] : [];
      } else if (data is List) {
        _lowStockReport = data;
      } else {
        _lowStockReport = [];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading low stock report: $e');
    }
  }

  // Load expired report
  Future<void> loadExpiredReport() async {
    try {
      final response = await _apiService.getExpiredReport();
      final data = response.data;
      
      if (data is Map && data['medicines'] != null) {
        _expiredReport = data['medicines'] is List ? data['medicines'] : [];
      } else if (data is List) {
        _expiredReport = data;
      } else {
        _expiredReport = [];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading expired report: $e');
    }
  }

  // Helper method to safely parse response data
  Map<String, dynamic>? _parseResponseData(dynamic data) {
    if (data is Map) {
      // Convert any string numbers to appropriate types
      final Map<String, dynamic> parsedData = {};
      data.forEach((key, value) {
        if (value is String) {
          // Try to parse numbers
          if (value.contains('.') && double.tryParse(value) != null) {
            parsedData[key] = double.parse(value);
          } else if (int.tryParse(value) != null) {
            parsedData[key] = int.parse(value);
          } else {
            parsedData[key] = value;
          }
        } else {
          parsedData[key] = value;
        }
      });
      return parsedData;
    }
    return null;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all reports
  Future<void> refreshAllReports() async {
    await Future.wait([
      loadDashboardSummary(),
      loadDailySalesReport(),
      loadLowStockReport(),
      loadExpiredReport(),
    ]);
  }
}