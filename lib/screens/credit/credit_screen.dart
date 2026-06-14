// lib/screens/credit/credit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/credit.dart';
import '../../models/medicine.dart';
import '../../providers/credit_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/medicine_search_dialog.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../utils/constants.dart';
import 'add_customer_screen.dart';

// Cart item model
class CartItem {
  Medicine medicine;
  int quantity;
  
  CartItem({
    required this.medicine,
    required this.quantity,
  });
  
  double get totalPrice => quantity * medicine.retailPrice;
}

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Customer? _selectedCustomer;
  Medicine? _selectedMedicine;
  List<CartItem> _cartItems = [];
  
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  
  String _customerSearchQuery = '';
  String _creditSearchQuery = '';
  int _selectedTabIndex = 0;
  
  // For payment dialog
  CreditSale? _selectedCreditSale;
  final _paymentDialogController = TextEditingController();
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final creditProvider = context.read<CreditProvider>();
    final medicineProvider = context.read<MedicineProvider>();
    
    await Future.wait([
      creditProvider.loadCustomers(),
      creditProvider.loadCreditSales(),
      medicineProvider.loadMedicines(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _paymentAmountController.dispose();
    _paymentDialogController.dispose();
    super.dispose();
  }

  Future<void> _showPaymentDialog(CreditSale sale) async {
    _selectedCreditSale = sale;
    _paymentDialogController.clear();
    _selectedPaymentMethod = 'cash';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Credit: ${sale.creditId}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Outstanding Balance:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'UGX ${sale.balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _paymentDialogController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount to Pay (UGX)',
                    hintText: 'Enter amount in UGX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Cash'),
                        selected: _selectedPaymentMethod == 'cash',
                        onSelected: (selected) {
                          setState(() => _selectedPaymentMethod = 'cash');
                        },
                        selectedColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Mobile Money'),
                        selected: _selectedPaymentMethod == 'mobile_money',
                        onSelected: (selected) {
                          setState(() => _selectedPaymentMethod = 'mobile_money');
                        },
                        selectedColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Bank Transfer'),
                        selected: _selectedPaymentMethod == 'bank_transfer',
                        onSelected: (selected) {
                          setState(() => _selectedPaymentMethod = 'bank_transfer');
                        },
                        selectedColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.primaryGreen),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(_paymentDialogController.text) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter valid amount')),
                            );
                            return;
                          }
                          if (amount > sale.balance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Amount exceeds balance of UGX ${sale.balance.toStringAsFixed(0)}')),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          
                          final success = await context.read<CreditProvider>().recordPayment(
                            sale.id,
                            amount,
                            _selectedPaymentMethod,
                            'Payment received',
                          );
                          
                          if (!mounted) return;
                          
                          if (success) {
                            await context.read<CreditProvider>().loadCreditSales();
                            _showReceiptOptions(sale, amount, _selectedPaymentMethod);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.read<CreditProvider>().error ?? 'Payment failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Process Payment'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReceiptOptions(CreditSale sale, double amount, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Receipt has been generated. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndPrintReceipt(sale, amount, method);
            },
            child: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintReceipt(CreditSale sale, double amount, String method) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Dervin Pharmacy', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  children: [
                    _buildReceiptRow('Receipt No:', 'RCP-${DateTime.now().millisecondsSinceEpoch}'),
                    _buildReceiptRow('Date:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
                    _buildReceiptRow('Credit ID:', sale.creditId),
                    _buildReceiptRow('Customer:', sale.customerName),
                    pw.Divider(),
                    _buildReceiptRow('Amount Paid:', 'UGX ${amount.toStringAsFixed(0)}', isBold: true),
                    _buildReceiptRow('Payment Method:', _getPaymentMethodName(method)),
                    _buildReceiptRow('New Balance:', 'UGX ${(sale.balance - amount).toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
              pw.Center(
                child: pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash': return 'Cash';
      case 'mobile_money': return 'Mobile Money';
      case 'bank_transfer': return 'Bank Transfer';
      default: return method;
    }
  }

  void _addToCart(Medicine medicine, int quantity) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.medicine.id == medicine.id
      );
      
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity += quantity;
      } else {
        _cartItems.add(CartItem(
          medicine: medicine,
          quantity: quantity,
        ));
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${medicine.name} x$quantity to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (index >= _cartItems.length) return;
    
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        final maxStock = _cartItems[index].medicine.quantity;
        if (newQuantity <= maxStock) {
          _cartItems[index].quantity = newQuantity;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $maxStock units available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  double _getCartTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _deleteCreditSale(CreditSale sale) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      'Delete Credit Sale',
      'Are you sure you want to delete credit sale ${sale.creditId}?\n\nThis action cannot be undone.',
    );
    
    if (!confirmed) return;
    
    final success = await context.read<CreditProvider>().deleteCreditSale(sale.id);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Credit sale deleted successfully')),
      );
      await context.read<CreditProvider>().loadCreditSales();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<CreditProvider>().error ?? 'Failed to delete credit sale'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printCreditInvoice(CreditSale sale) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CREDIT SALE INVOICE',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                    ),
                    pw.Text('Dervin Pharmacy', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  children: [
                    _buildReceiptRow('Credit ID:', sale.creditId),
                    _buildReceiptRow('Date Issued:', DateFormat('yyyy-MM-dd').format(sale.createdAt)),
                    _buildReceiptRow('Due Date:', DateFormat('yyyy-MM-dd').format(sale.dueDate)),
                    _buildReceiptRow('Customer:', sale.customerName),
                    _buildReceiptRow('Status:', sale.status.toUpperCase()),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    ...sale.items.map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                      child: pw.Text('• ${item.quantity}x ${item.medicineName} - UGX ${item.totalPrice.toStringAsFixed(0)}'),
                    )),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    _buildReceiptRow('Total Amount:', 'UGX ${sale.totalAmount.toStringAsFixed(0)}', isBold: true),
                    _buildReceiptRow('Amount Paid:', 'UGX ${sale.amountPaid.toStringAsFixed(0)}'),
                    _buildReceiptRow('Balance Due:', 'UGX ${sale.balance.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Please pay by ${DateFormat('yyyy-MM-dd').format(sale.dueDate)}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> _downloadCreditInvoice(CreditSale sale) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CREDIT SALE INVOICE',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                    ),
                    pw.Text('Dervin Pharmacy', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  children: [
                    _buildReceiptRow('Credit ID:', sale.creditId),
                    _buildReceiptRow('Date Issued:', DateFormat('yyyy-MM-dd').format(sale.createdAt)),
                    _buildReceiptRow('Due Date:', DateFormat('yyyy-MM-dd').format(sale.dueDate)),
                    _buildReceiptRow('Customer:', sale.customerName),
                    _buildReceiptRow('Status:', sale.status.toUpperCase()),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    ...sale.items.map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                      child: pw.Text('• ${item.quantity}x ${item.medicineName} - UGX ${item.totalPrice.toStringAsFixed(0)}'),
                    )),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    _buildReceiptRow('Total Amount:', 'UGX ${sale.totalAmount.toStringAsFixed(0)}', isBold: true),
                    _buildReceiptRow('Amount Paid:', 'UGX ${sale.amountPaid.toStringAsFixed(0)}'),
                    _buildReceiptRow('Balance Due:', 'UGX ${sale.balance.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Please pay by ${DateFormat('yyyy-MM-dd').format(sale.dueDate)}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'credit_invoice_${sale.creditId}.pdf',
    );
  }

  void _showMedicineSelector() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                width: double.maxFinite,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Medicine',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search medicine...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setStateDialog(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    
                    Expanded(
                      child: Consumer<MedicineProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading && provider.medicines.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final today = DateTime.now();
                          final todayMidnight = DateTime(today.year, today.month, today.day);
                          
                          var availableMedicines = provider.medicines
                              .where((m) => m.expiryDate.isAfter(todayMidnight) && m.quantity > 0)
                              .toList();
                          
                          if (searchQuery.isNotEmpty) {
                            availableMedicines = availableMedicines.where((m) =>
                              m.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              m.genericName.toLowerCase().contains(searchQuery.toLowerCase())
                            ).toList();
                          }

                          if (availableMedicines.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty ? 'No available medicines' : 'No matching medicines',
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: availableMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = availableMedicines[index];
                              final isLowStock = medicine.quantity <= medicine.minStockLevel;
                              final alreadyInCart = _cartItems.any((item) => item.medicine.id == medicine.id);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      _showQuantityDialog(medicine);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: isLowStock ? Colors.orange : AppColors.primaryGreen,
                                            child: Text(
                                              medicine.quantity.toString(),
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  medicine.name,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Stock: ${medicine.quantity} | UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (alreadyInCart)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Added',
                                                    style: TextStyle(
                                                      color: AppColors.primaryGreen,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'ADD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuantityDialog(Medicine medicine) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Add ${medicine.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) {
                            setStateDialog(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          quantity.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (quantity < medicine.quantity) {
                            setStateDialog(() {
                              quantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Only ${medicine.quantity} units available'),
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Available: ${medicine.quantity} units',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(medicine, quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'ADD TO CART (UGX ${(medicine.retailPrice * quantity).toStringAsFixed(0)})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
    );
    if (result == true && mounted) {
      await context.read<CreditProvider>().loadCustomers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully! You can now select them.')),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Credit Management',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),

      // Use darker green for better contrast
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,

      bottom: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() => _selectedTabIndex = index),

        // FIXED COLORS
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,

        indicatorColor: Colors.white,
        indicatorWeight: 3,

        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),

        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),

        tabs: const [
          Tab(text: 'New Sale'),
          Tab(text: 'Customers'),
          Tab(text: 'Credit Sales'),
        ],
      ),
    ),

    body: TabBarView(
      controller: _tabController,
      children: [
        _buildNewSaleTab(),
        _buildCustomersTab(),
        _buildCreditSalesTab(),
      ],
    ),

    floatingActionButton: _selectedTabIndex == 1
        ? FloatingActionButton(
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: _createNewCustomer,
          )
        : null,
  );
}

  Widget _buildNewSaleTab() {
    return Consumer2<CreditProvider, MedicineProvider>(
      builder: (context, creditProvider, medicineProvider, child) {
        if (creditProvider.isLoading && creditProvider.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Customer',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Customer>(
                            value: _selectedCustomer,
                            hint: const Text('Choose a customer'),
                            isExpanded: true,
                            items: creditProvider.customers
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.fullName),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCustomer = v),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _createNewCustomer,
                            icon: Icon(Icons.person_add, size: 18, color: AppColors.primaryGreen),
                            label: Text('Create new customer', style: TextStyle(color: AppColors.primaryGreen)),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ADD TO CART BUTTON
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showMedicineSelector,
                        icon: const Icon(Icons.add_shopping_cart, size: 28, color: Colors.white),
                        label: Text(
                          'ADD MEDICINE TO CART',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Cart Items Section
                    if (_cartItems.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cart Items (${_cartItems.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _cartItems.clear();
                              });
                            },
                            icon: const Icon(Icons.delete_sweep, color: Colors.red),
                            label: const Text(
                              'Clear Cart',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.medicine.name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              'UGX ${item.medicine.retailPrice.toStringAsFixed(0)} each',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeFromCart(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 18),
                                              onPressed: () => _updateQuantity(index, item.quantity - 1),
                                              constraints: const BoxConstraints(minWidth: 36),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                item.quantity.toString(),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 18),
                                              onPressed: () => _updateQuantity(index, item.quantity + 1),
                                              constraints: const BoxConstraints(minWidth: 36),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'UGX ${item.totalPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Notes Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes (Optional)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Add any notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Total and Create Button
            if (_cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'UGX ${_getCartTotal().toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedCustomer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a customer')),
                            );
                            return;
                          }
                          
                          final items = _cartItems.map((item) => ({
                            'medicine': item.medicine.id,
                            'quantity': item.quantity,
                            'unit_price': item.medicine.retailPrice,
                          })).toList();
                          
                          final totalAmount = _getCartTotal();
                          
                          final success = await creditProvider.createCreditSale({
                            'customer': _selectedCustomer!.id,
                            'items': items,
                            'total_amount': totalAmount,
                            'due_date': DateTime.now()
                                .add(const Duration(days: 30))
                                .toIso8601String()
                                .split('T')[0],
                            'notes': _notesController.text,
                          });
                          
                          if (!mounted) return;
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Credit sale created successfully')),
                            );
                            setState(() {
                              _cartItems.clear();
                              _notesController.clear();
                              _selectedCustomer = null;
                            });
                            await creditProvider.loadCreditSales();
                            _tabController.animateTo(2);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(creditProvider.error ?? 'Failed to create credit sale')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CREATE CREDIT SALE (${_cartItems.length} items)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, child) {
        final customers = creditProvider.searchCustomers(_customerSearchQuery);
        
        if (creditProvider.isLoading && customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => setState(() => _customerSearchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primaryGreen,
                        child: Text(customer.initials),
                      ),
                      title: Text(customer.fullName),
                      subtitle: Text(customer.phone),
                      trailing: Text(
                        'UGX ${customer.outstandingBalance.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                          _selectedTabIndex = 0;
                          _tabController.animateTo(0);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreditSalesTab() {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, child) {
        final creditSales = creditProvider.searchCreditSales(_creditSearchQuery);
        final overdue = creditProvider.getOverdueCreditSales();
        
        if (creditProvider.isLoading && creditSales.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (overdue.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have ${overdue.length} overdue credit sale(s)',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer, credit ID or medicine...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => setState(() => _creditSearchQuery = value),
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                itemCount: creditSales.length,
                itemBuilder: (context, index) {
                  final sale = creditSales[index];
                  final isFullyPaid = sale.balance <= 0;
                  final isOverdue = sale.isOverdue && !isFullyPaid;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: isFullyPaid 
                        ? AppColors.primaryLight 
                        : isOverdue 
                            ? Colors.red.shade50 
                            : Colors.white,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isFullyPaid 
                            ? AppColors.primaryGreen 
                            : isOverdue 
                                ? Colors.red 
                                : Colors.orange,
                        child: Icon(
                          isFullyPaid ? Icons.check : Icons.credit_card,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(sale.creditId),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${sale.customerName} • ${sale.items.length} item(s)'),
                          Text('Due: ${DateFormat('yyyy-MM-dd').format(sale.dueDate)}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'print') {
                            _printCreditInvoice(sale);
                          } else if (value == 'download') {
                            _downloadCreditInvoice(sale);
                          } else if (value == 'delete') {
                            _deleteCreditSale(sale);
                          } else if (value == 'payment') {
                            _showPaymentDialog(sale);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'print',
                            child: Row(
                              children: [
                                Icon(Icons.print, size: 20),
                                SizedBox(width: 8),
                                Text('Print Invoice'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download, size: 20),
                                SizedBox(width: 8),
                                Text('Download PDF'),
                              ],
                            ),
                          ),
                          if (!isFullyPaid)
                            const PopupMenuItem(
                              value: 'payment',
                              child: Row(
                                children: [
                                  Icon(Icons.payment, size: 20),
                                  SizedBox(width: 8),
                                  Text('Record Payment'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Credit ID', sale.creditId),
                              _buildInfoRow('Customer', sale.customerName),
                              _buildInfoRow('Due Date', DateFormat('yyyy-MM-dd').format(sale.dueDate)),
                              _buildInfoRow('Status', sale.status.toUpperCase()),
                              _buildInfoRow('Issued By', sale.issuedByName.isNotEmpty ? sale.issuedByName : 'Staff #${sale.issuedBy}'),
                              
                              const Divider(),
                              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...sale.items.map((item) => Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('${item.quantity}x ${item.medicineName}')),
                                    Text('UGX ${item.totalPrice.toStringAsFixed(0)}'),
                                  ],
                                ),
                              )),
                              
                              const Divider(),
                              _buildInfoRow('Total Amount', 'UGX ${sale.totalAmount.toStringAsFixed(0)}'),
                              _buildInfoRow('Amount Paid', 'UGX ${sale.amountPaid.toStringAsFixed(0)}'),
                              _buildInfoRow('Remaining Balance', 'UGX ${sale.balance.toStringAsFixed(0)}'),
                              
                              if (!isFullyPaid)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showPaymentDialog(sale),
                                      icon: const Icon(Icons.payment),
                                      label: const Text('RECORD PAYMENT'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}