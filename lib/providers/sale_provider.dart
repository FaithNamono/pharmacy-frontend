import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class SaleProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Sale> _sales = [];
  List<Sale> _dailySales = [];
  double _dailyTotal = 0;
  int _dailyTransactions = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  SaleProvider(this._apiService);

  // Getters
  List<Sale> get sales => _sales;
  List<Sale> get dailySales => _dailySales;
  double get dailyTotal => _dailyTotal;
  int get dailyTransactions => _dailyTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all sales with pagination handling
  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      _sales = [];
      _currentPage = 1;
      _hasMorePages = true;
    }

    if (!_hasMorePages || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSales(params: {
        'page': _currentPage,
      });

      // Handle both paginated and non-paginated responses
      List<dynamic> data;
      if (response.data is Map && response.data['results'] != null) {
        // Paginated response
        data = response.data['results'];
        _hasMorePages = response.data['next'] != null;
      } else if (response.data is List) {
        // Non-paginated response (plain array)
        data = response.data;
        _hasMorePages = false; // No pagination
      } else {
        data = [];
      }

      final newSales = data.map((json) => Sale.fromJson(json)).toList();

      if (newSales.isEmpty) {
        _hasMorePages = false;
      } else {
        _sales.addAll(newSales);
        _currentPage++;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load sales: $e';
      print('Error loading sales: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load daily sales
  Future<void> loadDailySales() async {
    try {
      final response = await _apiService.getDailySales();
      final data = response.data;
      
      // Parse with safety checks
      _dailyTotal = _parseDouble(data['total_sales']) ?? 0;
      _dailyTransactions = _parseInt(data['total_transactions']) ?? 0;
      
      final List<dynamic> salesData = data['sales'] is List ? data['sales'] : [];
      _dailySales = salesData.map((json) => Sale.fromJson(json)).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading daily sales: $e');
    }
  }

  // Get sale by ID
  Future<Sale?> getSaleById(int id) async {
    try {
      final response = await _apiService.getSale(id);
      return Sale.fromJson(response.data);
    } catch (e) {
      print('Error getting sale: $e');
      return null;
    }
  }

  // Create sale
  Future<bool> createSale(Map<String, dynamic> saleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createSale(saleData);
      final newSale = Sale.fromJson(response.data);
      
      _sales.insert(0, newSale);
      _dailySales.insert(0, newSale);
      
      // Update daily totals
      _dailyTotal += newSale.totalPrice;
      _dailyTransactions++;
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create sale: $e';
      print('Error creating sale: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get sales by date range
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _apiService.getSalesByDateRange(
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      );
      
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => Sale.fromJson(json)).toList();
    } catch (e) {
      print('Error getting sales by date: $e');
      return [];
    }
  }

  // Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to safely parse int values
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all sales data
  Future<void> refreshAll() async {
    await Future.wait([
      loadSales(refresh: true),
      loadDailySales(),
    ]);
  }
}