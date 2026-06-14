// lib/widgets/fill_prescription_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prescription.dart';
import '../providers/prescription_provider.dart';
import '../utils/constants.dart';  // ✅ Import for AppColors

class FillPrescriptionDialog extends StatefulWidget {
  final Prescription prescription;

  const FillPrescriptionDialog({super.key, required this.prescription});

  @override
  State<FillPrescriptionDialog> createState() => _FillPrescriptionDialogState();
}

class _FillPrescriptionDialogState extends State<FillPrescriptionDialog> {
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.prescription.items) {
      if (item.remainingQuantity > 0) {
        _quantityControllers[item.id] = TextEditingController(
          text: item.remainingQuantity.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFill() async {
    final itemsToFill = <Map<String, dynamic>>[];

    for (var item in widget.prescription.items) {
      if (item.remainingQuantity > 0) {
        final controller = _quantityControllers[item.id];
        final quantity = int.tryParse(controller?.text ?? '0') ?? 0;

        if (quantity > 0) {
          if (quantity > item.remainingQuantity) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cannot fill more than remaining for ${item.medicineName}. Remaining: ${item.remainingQuantity}',
                  ),
                ),
              );
            }
            return;
          }
          itemsToFill.add({
            'item_id': item.id,
            'quantity_filled': quantity,
          });
        }
      }
    }

    if (itemsToFill.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to fill')),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final result = await context.read<PrescriptionProvider>().fillPrescription(
      widget.prescription.id,
      itemsToFill,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fill prescription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFillableItems =
        widget.prescription.items.any((item) => item.remainingQuantity > 0);

    if (!hasFillableItems) {
      return AlertDialog(
        title: const Text('All Items Filled'),
        content: const Text('This prescription has been fully filled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Fill: ${widget.prescription.prescriptionId}'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Patient: ${widget.prescription.patientName}'),
            const Divider(),
            ...widget.prescription.items.map((item) {
              if (item.remainingQuantity <= 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.medicineName} (${item.filledQuantity}/${item.prescribedQuantity})',
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Prescribed: ${item.prescribedQuantity} | Filled: ${item.filledQuantity}'),
                    Text('Remaining: ${item.remainingQuantity}', style: const TextStyle(color: Colors.blue)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityControllers[item.id],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Quantity',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _quantityControllers[item.id]?.text = item.remainingQuantity.toString();
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(50, 40),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('MAX', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitFill,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}