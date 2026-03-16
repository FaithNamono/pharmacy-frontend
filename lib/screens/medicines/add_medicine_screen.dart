import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../models/supplier.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({Key? key}) : super(key: key);

  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _expiryDate;
  Category? _selectedCategory;
  Supplier? _selectedSupplier;
  
  bool _isLoading = false;
  String? _expiryError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await Future.wait([
      provider.loadCategories(),
      provider.loadSuppliers(),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _batchNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(), // CRITICAL: This prevents selecting past dates
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiryError = null;
      });
    }
  }

  String? _validateExpiryDate() {
    if (_expiryDate == null) {
      return 'Please select expiry date';
    }
    
    // Get today's date at midnight for accurate comparison
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    if (_expiryDate!.isBefore(todayMidnight)) {
      return 'Expiry date cannot be in the past. Selected date: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}';
    }
    
    return null;
  }

  Future<void> _handleSubmit() async {
    // Clear previous errors
    setState(() {
      _expiryError = null;
    });

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate expiry date
    final expiryValidation = _validateExpiryDate();
    if (expiryValidation != null) {
      setState(() {
        _expiryError = expiryValidation;
      });
      
      // Show snackbar for immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $expiryValidation'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final medicineData = {
      'name': _nameController.text.trim(),
      'generic_name': _genericNameController.text.trim(),
      'category': _selectedCategory!.id,
      'supplier': _selectedSupplier!.id,
      'price': double.parse(_priceController.text),
      'quantity': int.parse(_quantityController.text),
      'min_stock_level': int.parse(_minStockController.text),
      'expiry_date': _expiryDate!.toIso8601String().split('T')[0],
      'batch_number': _batchNumberController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final provider = Provider.of<MedicineProvider>(context, listen: false);
    final success = await provider.addMedicine(medicineData);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Medicine added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to add medicine'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canAdd = authProvider.currentUser?.isAdmin ?? false;

    if (!canAdd) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Medicine'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to add medicines',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Basic Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _nameController,
                            label: 'Medicine Name *',
                            prefixIcon: Icons.medical_services,
                            validator: Validators.required,
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _genericNameController,
                            label: 'Generic Name',
                            prefixIcon: Icons.science,
                          ),
                          const SizedBox(height: 16),
                          
                          // Category Dropdown
                          DropdownButtonFormField<Category>(
                            value: _selectedCategory,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: provider.categories.map((category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Text(
                                  category.name,
                                  style: GoogleFonts.poppins(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) return 'Please select a category';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Supplier Dropdown
                          DropdownButtonFormField<Supplier>(
                            value: _selectedSupplier,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Supplier *',
                              prefixIcon: const Icon(Icons.business),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: provider.suppliers.map((supplier) {
                              return DropdownMenuItem<Supplier>(
                                value: supplier,
                                child: Text(
                                  supplier.name,
                                  style: GoogleFonts.poppins(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (Supplier? value) {
                              setState(() {
                                _selectedSupplier = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) return 'Please select a supplier';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pricing and Stock
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing & Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _priceController,
                                  label: 'Price *',
                                  prefixIcon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  validator: Validators.positiveNumber,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: _quantityController,
                                  label: 'Quantity *',
                                  prefixIcon: Icons.inventory,
                                  keyboardType: TextInputType.number,
                                  validator: Validators.integer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _minStockController,
                            label: 'Minimum Stock Level *',
                            prefixIcon: Icons.warning,
                            keyboardType: TextInputType.number,
                            validator: Validators.integer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expiry and Batch - CRITICAL SECTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry & Batch',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Expiry Date Picker with validation
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date *',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                errorText: _expiryError,
                                errorStyle: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              child: Text(
                                _expiryDate == null
                                    ? 'Select Date'
                                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                style: GoogleFonts.poppins(
                                  color: _expiryError != null ? Colors.red : null,
                                ),
                              ),
                            ),
                          ),
                          
                          // Warning message
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Expiry date must be in the future. Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _batchNumberController,
                            label: 'Batch Number',
                            prefixIcon: Icons.qr_code,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            prefixIcon: Icons.description,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  CustomButton(
                    text: 'ADD MEDICINE',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}