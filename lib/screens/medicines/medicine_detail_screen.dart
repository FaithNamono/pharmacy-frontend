import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';           // ADD THIS
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';


class MedicineDetailScreen extends StatefulWidget {
  final int medicineId;

  const MedicineDetailScreen({Key? key, required this.medicineId}) : super(key: key);

  @override
  _MedicineDetailScreenState createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  Medicine? _medicine;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isDeleting = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicineDetails();
  }

  Future<void> _loadMedicineDetails() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    _medicine = await provider.getMedicineById(widget.medicineId);
    
    if (_medicine != null) {
      _nameController.text = _medicine!.name;
      _genericNameController.text = _medicine!.genericName;
      _priceController.text = _medicine!.price.toString();
      _quantityController.text = _medicine!.quantity.toString();
      _minStockController.text = _medicine!.minStockLevel.toString();
      _batchNumberController.text = _medicine!.batchNumber;
      _descriptionController.text = _medicine!.description;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isEditing = true);

      final updatedData = {
        'name': _nameController.text.trim(),
        'generic_name': _genericNameController.text.trim(),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'min_stock_level': int.parse(_minStockController.text),
        'batch_number': _batchNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      final provider = Provider.of<MedicineProvider>(context, listen: false);
      final success = await provider.updateMedicine(widget.medicineId, updatedData);

      setState(() => _isEditing = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMedicineDetails();
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);

      final provider = Provider.of<MedicineProvider>(context, listen: false);
      final success = await provider.deleteMedicine(widget.medicineId);

      setState(() => _isDeleting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canEdit = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Toggle edit mode
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
      body: _isLoading || _isDeleting
          ? const LoadingIndicator()
          : _medicine == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Medicine not found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Status Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusCard(
                                'Stock Status',
                                _medicine!.stockStatus,
                                _medicine!.stockStatusColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                'Expiry Status',
                                _medicine!.expiryStatus,
                                _medicine!.expiryStatusColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

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
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                _buildInfoRow('Medicine Name', _medicine!.name),
                                _buildInfoRow('Generic Name', _medicine!.genericName),
                                _buildInfoRow('Category', _medicine!.categoryName),
                                _buildInfoRow('Supplier', _medicine!.supplierName),
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
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                _buildInfoRow('Price', 'UGX ${_medicine!.price.toStringAsFixed(0)}'),
                                _buildInfoRow('Current Stock', '${_medicine!.quantity} units'),
                                _buildInfoRow('Minimum Stock', '${_medicine!.minStockLevel} units'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Expiry and Batch
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
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                _buildInfoRow(
                                  'Expiry Date',
                                  '${_medicine!.expiryDate.day}/${_medicine!.expiryDate.month}/${_medicine!.expiryDate.year}',
                                ),
                                _buildInfoRow('Batch Number', _medicine!.batchNumber),
                                _buildInfoRow('Days Until Expiry', '${_medicine!.daysUntilExpiry} days'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        if (_medicine!.description.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _medicine!.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard(String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}