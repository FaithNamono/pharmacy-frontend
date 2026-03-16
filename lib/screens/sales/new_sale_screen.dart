import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({Key? key}) : super(key: key);

  @override
  _NewSaleScreenState createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  Medicine? _selectedMedicine;
  int _quantity = 1;
  double _totalPrice = 0;
  bool _isLoading = false;
  String? _expiryError;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await provider.loadMedicines();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTotalPrice() {
    if (_selectedMedicine != null) {
      setState(() {
        _totalPrice = _selectedMedicine!.price * _quantity;
      });
    }
  }

  String? _validateMedicine(Medicine? medicine) {
    if (medicine == null) return null;
    
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    if (medicine.expiryDate.isBefore(todayMidnight)) {
      return 'This medicine expired on ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year} and cannot be sold';
    }
    
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMedicine == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a medicine'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // CRITICAL: Check if medicine is expired
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      
      if (_selectedMedicine!.expiryDate.isBefore(todayMidnight)) {
        final errorMsg = 'Cannot sell expired medicine: ${_selectedMedicine!.name} (Expired on ${_selectedMedicine!.expiryDate.day}/${_selectedMedicine!.expiryDate.month}/${_selectedMedicine!.expiryDate.year})';
        
        setState(() {
          _expiryError = errorMsg;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (_quantity > _selectedMedicine!.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient stock. Available: ${_selectedMedicine!.quantity}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _expiryError = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final saleData = {
        'medicine': _selectedMedicine!.id,
        'user': authProvider.currentUser!.id,
        'quantity': _quantity,
        'notes': _notesController.text.trim(),
      };

      final provider = Provider.of<SaleProvider>(context, listen: false);
      final success = await provider.createSale(saleData);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sale completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to process sale'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
      ),
      body: Consumer2<MedicineProvider, SaleProvider>(
        builder: (context, medicineProvider, saleProvider, child) {
          if (medicineProvider.isLoading && medicineProvider.medicines.isEmpty) {
            return const LoadingIndicator();
          }

          // CRITICAL: Filter out expired medicines from the dropdown
          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);
          
          final availableMedicines = medicineProvider.medicines
              .where((m) => !m.expiryDate.isBefore(todayMidnight))
              .toList();

          // Show warning if there are expired medicines in stock
          final expiredCount = medicineProvider.medicines.length - availableMedicines.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Expired Medicines Warning
                  if (expiredCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$expiredCount expired medicine${expiredCount > 1 ? 's' : ''} in stock (hidden from selection)',
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Medicine Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Medicine',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Medicine Dropdown
                          DropdownButtonFormField<Medicine>(
                            value: _selectedMedicine,
                            decoration: InputDecoration(
                              labelText: 'Medicine *',
                              prefixIcon: const Icon(Icons.medical_services),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              errorText: _expiryError,
                              errorStyle: GoogleFonts.poppins(color: Colors.red),
                            ),
                            items: availableMedicines.map((medicine) {
                              return DropdownMenuItem<Medicine>(
                                value: medicine,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(medicine.name),
                                    Text(
                                      'Stock: ${medicine.quantity} | Price: UGX ${medicine.price.toStringAsFixed(0)} | Expires: ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMedicine = value;
                                _expiryError = null;
                                _updateTotalPrice();
                              });
                            },
                            validator: (value) {
                              if (value == null) return 'Please select a medicine';
                              return null;
                            },
                          ),
                          
                          if (availableMedicines.isEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No available medicines in stock. All medicines may be expired.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (_selectedMedicine != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available Stock:',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedMedicine!.quantity} units',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: _selectedMedicine!.quantity > 10
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity and Price
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale Details',
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
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity *',
                                    prefixIcon: const Icon(Icons.format_list_numbered),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _quantity = int.tryParse(value) ?? 1;
                                      _updateTotalPrice();
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }
                                    final quantity = int.tryParse(value);
                                    if (quantity == null || quantity <= 0) {
                                      return 'Please enter a valid quantity';
                                    }
                                    if (_selectedMedicine != null && quantity > _selectedMedicine!.quantity) {
                                      return 'Insufficient stock';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          if (_selectedMedicine != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Unit Price:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'UGX ${_selectedMedicine!.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Price:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'UGX ${_totalPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes
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
                          
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  CustomButton(
                    text: 'COMPLETE SALE',
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