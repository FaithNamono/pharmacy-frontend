// lib/screens/prescriptions/prescription_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/prescription.dart';
import '../../models/medicine.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/prescription_pdf_service.dart';
import '../../utils/constants.dart';
import '../../widgets/medicine_search_dialog_prescription.dart';
import '../../widgets/fill_prescription_dialog.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PrescriptionProvider>().loadPrescriptions();
        context.read<MedicineProvider>().loadMedicines();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Prescriptions',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.white,
    ),
    onPressed: () => Navigator.pop(context),
  ),

  backgroundColor: AppColors.primaryDark,
  foregroundColor: Colors.white,

  bottom: TabBar(
    controller: _tabController,

    // FIXED COLORS
    indicatorColor: Colors.white,
    indicatorWeight: 3,

    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,

    labelStyle: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),

    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),

    tabs: const [
      Tab(text: 'All Prescriptions'),
      Tab(text: 'Add Prescription'),
      Tab(text: 'Pending'),
    ],
  ),
),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          PrescriptionListTab(),
          AddPrescriptionTab(),
          PendingPrescriptionsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _selectedIndex = 1);
              },
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ============================================================
// PRESCRIPTION LIST TAB
// ============================================================

class PrescriptionListTab extends StatelessWidget {
  const PrescriptionListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrescriptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.prescriptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.prescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No prescriptions yet',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add a prescription',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPrescriptions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.prescriptions.length,
            itemBuilder: (context, index) {
              final rx = provider.prescriptions[index];

              return Dismissible(
                key: Key(rx.prescriptionId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Prescription'),
                      content: Text('Are you sure you want to delete ${rx.prescriptionId} for ${rx.patientName}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  final success = await provider.deletePrescription(rx.id);
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prescription deleted successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(provider.error ?? 'Failed to delete'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: rx.statusColor.withOpacity(0.1),
                      child: Text(
                        rx.patientName[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: rx.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      rx.patientName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rx.prescriptionId),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.medical_services, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${rx.items.length} items', style: GoogleFonts.poppins(fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.person, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                rx.doctorName,
                                style: GoogleFonts.poppins(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (rx.prescriptionImage != null && rx.prescriptionImage!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.image, size: 12, color: Colors.blue),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rx.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rx.statusDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: rx.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(rx.issueDate),
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                    onTap: () => _showPrescriptionDetails(context, rx, provider),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static void _showPrescriptionDetails(
    BuildContext context,
    Prescription rx,
    PrescriptionProvider provider,
  ) {
    final filledCount = rx.items.fold<int>(0, (sum, item) => sum + item.filledQuantity);
    final totalCount = rx.items.fold<int>(0, (sum, item) => sum + item.prescribedQuantity);
    final progress = totalCount > 0 ? filledCount / totalCount : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              // Make the sheet take up to 90% of screen height
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ FIXED: No Expanded inside Row — use Flexible for title,
                    // plain Row(mainAxisSize.min) for icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Prescription Details',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                Navigator.pop(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Prescription'),
                                    content: Text('Delete ${rx.prescriptionId}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await provider.deletePrescription(rx.id);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) provider.loadPrescriptions();
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.blue),
                              tooltip: 'Download PDF',
                              onPressed: () async {
                                await PrescriptionPdfService.generateAndDownload(rx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PDF downloaded successfully')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.green),
                              tooltip: 'Print',
                              onPressed: () async {
                                await PrescriptionPdfService.generateAndPrint(rx);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.orange),
                              tooltip: 'Share',
                              onPressed: () async {
                                await Share.share(
                                  'Prescription ${rx.prescriptionId} for ${rx.patientName}',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (rx.status == 'partially_filled' || rx.status == 'pending') ...[
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$filledCount of $totalCount items filled',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildDetailRow('RX Number', rx.prescriptionId),
                    _buildDetailRow('Patient', rx.patientName),
                    if (rx.patientAge != null) _buildDetailRow('Age', '${rx.patientAge}'),
                    if (rx.patientPhone.isNotEmpty) _buildDetailRow('Phone', rx.patientPhone),
                    _buildDetailRow('Doctor', rx.doctorName),
                    _buildDetailRow('Hospital', rx.hospital.isEmpty ? 'Not specified' : rx.hospital),
                    _buildDetailRow('Issue Date', DateFormat('dd/MM/yyyy').format(rx.issueDate)),
                    _buildDetailRow('Expiry Date', DateFormat('dd/MM/yyyy').format(rx.expiryDate)),
                    _buildDetailRow('Status', rx.statusDisplay),
                    if (rx.diagnosis.isNotEmpty) _buildDetailRow('Diagnosis', rx.diagnosis),
                    if (rx.notes.isNotEmpty) _buildDetailRow('Notes', rx.notes),
                    if (rx.prescriptionImage != null && rx.prescriptionImage!.isNotEmpty)
                      _buildDetailRow('Has Image', 'Yes ✓'),

                    if (rx.items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Medicines',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...rx.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.medicineName, style: GoogleFonts.poppins(fontSize: 14)),
                                  if (item.dosageInstructions.isNotEmpty)
                                    Text(
                                      item.dosageInstructions,
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.prescribedQuantity} units',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                ),
                                if (item.filledQuantity > 0)
                                  Text(
                                    'Filled: ${item.filledQuantity}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: item.isFullyFilled ? Colors.green : Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ],

                    const SizedBox(height: 24),

                    if (rx.status == 'pending' || rx.status == 'partially_filled')
                      CustomButton(
                        text: 'FILL PRESCRIPTION',
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => FillPrescriptionDialog(prescription: rx),
                          );
                          if (result == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Prescription filled successfully')),
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) provider.loadPrescriptions();
                            });
                          }
                        },
                        isFullWidth: true,
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD PRESCRIPTION TAB
// ============================================================

class AddPrescriptionTab extends StatefulWidget {
  const AddPrescriptionTab({super.key});

  @override
  _AddPrescriptionTabState createState() => _AddPrescriptionTabState();
}

class _AddPrescriptionTabState extends State<AddPrescriptionTab> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorLicenseController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  Uint8List? _prescriptionImageBytes;
  final List<PrescriptionItemModel> _prescriptionItems = [];

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientPhoneController.dispose();
    _doctorNameController.dispose();
    _doctorLicenseController.dispose();
    _hospitalController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _prescriptionImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Camera on web requires HTTPS. Please use gallery instead.'),
                    ),
                  );
                } else {
                  _pickImage(ImageSource.camera);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addMedicineItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Medicine',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: MedicineSearchDialogPrescription(
                      onSelect: (medicine) {
                        Navigator.pop(context);
                        _showMedicineQuantityDialog(medicine);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMedicineQuantityDialog(Medicine medicine) {
    final quantityController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add ${medicine.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stock: ${medicine.quantity} | Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage Instructions',
                    hintText: 'e.g., 1x2 daily',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 7 days',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final qty = int.tryParse(quantityController.text) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid quantity')),
                  );
                  return;
                }
                if (qty > medicine.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Insufficient stock. Available: ${medicine.quantity}')),
                  );
                  return;
                }
                setState(() {
                  _prescriptionItems.add(PrescriptionItemModel(
                    medicineId: medicine.id,
                    medicineName: medicine.name,
                    quantity: qty,
                    dosageInstructions: dosageController.text,
                    duration: durationController.text,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrescriptionProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Patient Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _patientNameController,
                          label: 'Patient Name *',
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter patient name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _patientAgeController,
                                label: 'Age',
                                prefixIcon: Icons.cake,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _patientPhoneController,
                                label: 'Phone',
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Doctor Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _doctorNameController,
                          label: 'Doctor Name *',
                          prefixIcon: Icons.medical_services,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter doctor name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _doctorLicenseController,
                                label: 'License Number',
                                prefixIcon: Icons.badge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _hospitalController,
                                label: 'Hospital',
                                prefixIcon: Icons.local_hospital,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Prescription Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription Details',
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
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _issueDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null && mounted) {
                                    setState(() => _issueDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Issue Date',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_issueDate),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _expiryDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null && mounted) {
                                    setState(() => _expiryDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_expiryDate),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _diagnosisController,
                          label: 'Diagnosis',
                          prefixIcon: Icons.health_and_safety,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _notesController,
                          label: 'Notes',
                          prefixIcon: Icons.note,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Prescription Image
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription Image',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_prescriptionImageBytes != null)
                          Stack(
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: MemoryImage(_prescriptionImageBytes!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    if (mounted) setState(() => _prescriptionImageBytes = null);
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: _showImageOptions,
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to add prescription image'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Medicines
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Medicines',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            IconButton(
                              onPressed: _addMedicineItem,
                              icon: const Icon(Icons.add_circle),
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_prescriptionItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No medicines added yet.\nTap + to add medicines',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _prescriptionItems.length,
                            itemBuilder: (context, index) {
                              final item = _prescriptionItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey.shade50,
                                child: ListTile(
                                  title: Text(
                                    item.medicineName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Quantity: ${item.quantity}'),
                                      if (item.dosageInstructions.isNotEmpty)
                                        Text('Dosage: ${item.dosageInstructions}'),
                                      if (item.duration.isNotEmpty)
                                        Text('Duration: ${item.duration}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      if (mounted) setState(() => _prescriptionItems.removeAt(index));
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: _isSaving ? 'SAVING...' : 'SAVE PRESCRIPTION',
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (_prescriptionItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please add at least one medicine'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (mounted) setState(() => _isSaving = true);

                            final prescriptionData = {
                              'patient_name': _patientNameController.text.trim(),
                              'patient_age': int.tryParse(_patientAgeController.text),
                              'patient_phone': _patientPhoneController.text.trim(),
                              'doctor_name': _doctorNameController.text.trim(),
                              'doctor_license': _doctorLicenseController.text.trim(),
                              'hospital': _hospitalController.text.trim(),
                              'issue_date': _issueDate.toIso8601String().split('T')[0],
                              'expiry_date': _expiryDate.toIso8601String().split('T')[0],
                              'diagnosis': _diagnosisController.text.trim(),
                              'notes': _notesController.text.trim(),
                              'items': _prescriptionItems
                                  .map((item) => ({
                                        'medicine': item.medicineId,
                                        'prescribed_quantity': item.quantity,
                                        'dosage_instructions': item.dosageInstructions,
                                        'duration': item.duration,
                                      }))
                                  .toList(),
                            };

                            final success = await provider.createPrescription(
                              prescriptionData,
                              imageBytes: _prescriptionImageBytes,
                            );

                            if (mounted) setState(() => _isSaving = false);

                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Prescription saved successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _patientNameController.clear();
                              _patientAgeController.clear();
                              _patientPhoneController.clear();
                              _doctorNameController.clear();
                              _doctorLicenseController.clear();
                              _hospitalController.clear();
                              _diagnosisController.clear();
                              _notesController.clear();
                              if (mounted) {
                                setState(() {
                                  _prescriptionItems.clear();
                                  _prescriptionImageBytes = null;
                                  _issueDate = DateTime.now();
                                  _expiryDate = DateTime.now().add(const Duration(days: 30));
                                });
                              }
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.error ?? 'Failed to save prescription'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  isFullWidth: true,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// PENDING PRESCRIPTIONS TAB
// ============================================================

class PendingPrescriptionsTab extends StatelessWidget {
  const PendingPrescriptionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrescriptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.pendingPrescriptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.pendingPrescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No pending prescriptions',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPrescriptions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingPrescriptions.length,
            itemBuilder: (context, index) {
              final rx = provider.pendingPrescriptions[index];
              final filledCount = rx.items.fold<int>(0, (sum, item) => sum + item.filledQuantity);
              final totalCount = rx.items.fold<int>(0, (sum, item) => sum + item.prescribedQuantity);
              final progress = totalCount > 0 ? filledCount / totalCount : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rx.patientName,
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  rx.prescriptionId,
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$filledCount/$totalCount filled',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showPrescriptionSummary(context, rx, provider),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('VIEW'),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => FillPrescriptionDialog(prescription: rx),
                                );
                                if (result == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('✅ Prescription filled successfully')),
                                  );
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) provider.loadPrescriptions();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'FILL NOW',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
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
        );
      },
    );
  }

  void _showPrescriptionSummary(
    BuildContext context,
    Prescription rx,
    PrescriptionProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Prescription Summary',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.blue),
                      tooltip: 'Download PDF',
                      onPressed: () async {
                        await PrescriptionPdfService.generateAndDownload(rx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF downloaded successfully')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Patient', rx.patientName),
                _buildDetailRow('Doctor', rx.doctorName),
                _buildDetailRow('Issue Date', DateFormat('dd/MM/yyyy').format(rx.issueDate)),
                _buildDetailRow('Expiry Date', DateFormat('dd/MM/yyyy').format(rx.expiryDate)),
                const Divider(),
                ...rx.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.medicineName, style: GoogleFonts.poppins()),
                      ),
                      Text(
                        '${item.filledQuantity}/${item.prescribedQuantity}',
                        style: GoogleFonts.poppins(
                          color: item.isFullyFilled ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'FILL PRESCRIPTION',
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog<bool>(
                      context: context,
                      builder: (context) => FillPrescriptionDialog(prescription: rx),
                    ).then((result) {
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Prescription filled successfully')),
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) provider.loadPrescriptions();
                        });
                      }
                    });
                  },
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER MODEL CLASS
// ============================================================
 
class PrescriptionItemModel {
  final int medicineId;
  final String medicineName;
  final int quantity;
  final String dosageInstructions;
  final String duration;

  PrescriptionItemModel({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.dosageInstructions,
    required this.duration,
  });
}