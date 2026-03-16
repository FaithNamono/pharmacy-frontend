import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';

class MedicineProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Medicine> _medicines = [];
  List<Medicine> _lowStockMedicines = [];
  List<Medicine> _expiringMedicines = [];
  List<Medicine> _expiredMedicines = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  MedicineProvider(this._apiService);

  // Getters
  List<Medicine> get medicines => _medicines;
  List<Medicine> get lowStockMedicines => _lowStockMedicines;
  List<Medicine> get expiringMedicines => _expiringMedicines;
  List<Medicine> get expiredMedicines => _expiredMedicines;
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all medicines with pagination handling
  Future<void> loadMedicines({bool refresh = false}) async {
    if (refresh) {
      _medicines = [];
      _currentPage = 1;
      _hasMorePages = true;
    }

    if (!_hasMorePages || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getMedicines(params: {
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

      final newMedicines = data.map((json) => Medicine.fromJson(json)).toList();

      if (newMedicines.isEmpty) {
        _hasMorePages = false;
      } else {
        _medicines.addAll(newMedicines);
        _currentPage++;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      print('Error loading medicines: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load low stock medicines
  Future<void> loadLowStockMedicines() async {
    try {
      final response = await _apiService.getLowStockMedicines();
      
      List<dynamic> data;
      if (response.data is Map && response.data['medicines'] != null) {
        data = response.data['medicines'];
      } else if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _lowStockMedicines = data.map((json) => Medicine.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading low stock: $e');
    }
  }

  // Load expiring medicines
  Future<void> loadExpiringMedicines() async {
    try {
      final response = await _apiService.getExpiringMedicines();
      
      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _expiringMedicines = data.map((json) => Medicine.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading expiring: $e');
    }
  }

  // Load expired medicines
  Future<void> loadExpiredMedicines() async {
    try {
      final response = await _apiService.getExpiredMedicines();
      
      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _expiredMedicines = data.map((json) => Medicine.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading expired: $e');
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      
      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _categories = data.map((json) => Category.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Load suppliers
  Future<void> loadSuppliers() async {
    try {
      final response = await _apiService.getSuppliers();
      
      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _suppliers = data.map((json) => Supplier.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(int id) async {
    try {
      final response = await _apiService.getMedicine(id);
      return Medicine.fromJson(response.data);
    } catch (e) {
      print('Error getting medicine: $e');
      return null;
    }
  }

  // Add medicine
  Future<bool> addMedicine(Map<String, dynamic> medicineData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createMedicine(medicineData);
      final newMedicine = Medicine.fromJson(response.data);
      _medicines.insert(0, newMedicine);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      print('Error adding medicine: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update medicine
  Future<bool> updateMedicine(int id, Map<String, dynamic> medicineData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateMedicine(id, medicineData);
      final updatedMedicine = Medicine.fromJson(response.data);
      
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index != -1) {
        _medicines[index] = updatedMedicine;
      }

      // Also update in other lists if present
      final lowStockIndex = _lowStockMedicines.indexWhere((m) => m.id == id);
      if (lowStockIndex != -1) {
        _lowStockMedicines[lowStockIndex] = updatedMedicine;
      }

      final expiringIndex = _expiringMedicines.indexWhere((m) => m.id == id);
      if (expiringIndex != -1) {
        _expiringMedicines[expiringIndex] = updatedMedicine;
      }

      final expiredIndex = _expiredMedicines.indexWhere((m) => m.id == id);
      if (expiredIndex != -1) {
        _expiredMedicines[expiredIndex] = updatedMedicine;
      }

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      print('Error updating medicine: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete medicine
  Future<bool> deleteMedicine(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteMedicine(id);
      _medicines.removeWhere((m) => m.id == id);
      _lowStockMedicines.removeWhere((m) => m.id == id);
      _expiringMedicines.removeWhere((m) => m.id == id);
      _expiredMedicines.removeWhere((m) => m.id == id);
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      print('Error deleting medicine: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadMedicines(refresh: true),
      loadLowStockMedicines(),
      loadExpiringMedicines(),
      loadExpiredMedicines(),
      loadCategories(),
      loadSuppliers(),
    ]);
  }
}