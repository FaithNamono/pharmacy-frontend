import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';

class QRScannerWeb extends StatefulWidget {
  const QRScannerWeb({super.key});

  @override
  State<QRScannerWeb> createState() => _QRScannerWebState();
}

class _QRScannerWebState extends State<QRScannerWeb> {
  final TextEditingController _codeController = TextEditingController();
  String _searchResult = '';

  void _processCode(String code) {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    
    try {
      final medicine = medicineProvider.medicines.firstWhere(
        (m) => m.barcode == code,
      );
      
      setState(() {
        _searchResult = '✅ Found: ${medicine.name}';
      });
      
      _showMedicineFoundDialog(code, medicine);
      
    } catch (e) {
      setState(() {
        _searchResult = '❌ Medicine not found with barcode: $code';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine not found with this barcode'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMedicineFoundDialog(String code, Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Medicine Found!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Barcode: $code',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.veryLightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        medicine.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Batch:', style: GoogleFonts.poppins(fontSize: 13)),
                          Text(medicine.batchNumber, style: GoogleFonts.poppins(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expiry:', style: GoogleFonts.poppins(fontSize: 13)),
                          Text(
                            '${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stock:', style: GoogleFonts.poppins(fontSize: 13)),
                          Text('${medicine.quantity} units', style: GoogleFonts.poppins(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Price:', style: GoogleFonts.poppins(fontSize: 13)),
                          Text('UGX ${medicine.retailPrice.toStringAsFixed(0)}', 
                               style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'VIEW DETAILS',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/medicine-detail',
                          arguments: {'id': medicine.id},
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _codeController.clear();
                  setState(() {
                    _searchResult = '';
                  });
                },
                child: const Text('SCAN AGAIN'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medicine'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(  // Wrap everything in SingleChildScrollView
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Camera not available on web.\nEnter barcode manually or use mobile device for camera scanning.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter Barcode Manually',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Barcode/QR Code',
                hintText: 'Enter the barcode number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              onSubmitted: _processCode,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'SEARCH',
              onPressed: () => _processCode(_codeController.text),
            ),
            if (_searchResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _searchResult.contains('✅') 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _searchResult,
                  style: GoogleFonts.poppins(
                    color: _searchResult.contains('✅') 
                        ? Colors.green.shade700 
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Sample Barcodes (for testing)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSampleCard('123456789012', 'Paracetamol 500mg'),
            _buildSampleCard('234567890123', 'Amoxicillin 250mg'),
            _buildSampleCard('345678901234', 'Ibuprofen 200mg'),
            _buildSampleCard('456789012345', 'Vitamin C 100mg'),
            const SizedBox(height: 20), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSampleCard(String code, String name) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.qr_code, color: Colors.grey),
        title: Text(code),
        subtitle: Text(name),
        trailing: Icon(Icons.search, color: AppColors.primaryGreen),
        onTap: () {
          _codeController.text = code;
          _processCode(code);
        },
      ),
    );
  }
}