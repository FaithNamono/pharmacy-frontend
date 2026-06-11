import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';

class QRScannerMobile extends StatefulWidget {
  const QRScannerMobile({super.key});

  @override
  State<QRScannerMobile> createState() => _QRScannerMobileState();
}

class _QRScannerMobileState extends State<QRScannerMobile> with WidgetsBindingObserver {
  MobileScannerController? cameraController;
  bool isScanning = true;
  String? lastScannedCode;
  bool isTorchOn = false;
  bool isCameraInitialized = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
    if (state == AppLifecycleState.paused) {
      cameraController?.stop();
    }
  }

  Future<void> _initCamera() async {
    try {
      if (cameraController != null) {
        cameraController!.dispose();
      }
      
      cameraController = MobileScannerController(
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.codabar,
          BarcodeFormat.pdf417,
          BarcodeFormat.aztec,
          BarcodeFormat.dataMatrix,
        ],
        facing: CameraFacing.back,
        torchEnabled: false,
        detectionSpeed: DetectionSpeed.normal,
      );

      await cameraController!.start();
      
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
          errorMessage = null;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to initialize camera. Please check permissions.';
          isCameraInitialized = false;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty && code != lastScannedCode) {
        setState(() {
          lastScannedCode = code;
          isScanning = false;
        });
        
        HapticFeedback.selectionClick();
        _processScannedCode(code);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    
    Medicine? foundMedicine;
    try {
      foundMedicine = medicineProvider.medicines.firstWhere(
        (m) => m.barcode == code,
      );
    } catch (e) {
      foundMedicine = null;
    }
    
    if (mounted) {
      if (foundMedicine != null) {
        _showMedicineFoundDialog(code, foundMedicine);
      } else {
        _showMedicineNotFoundDialog(code);
      }
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
                  setState(() {
                    isScanning = true;
                    lastScannedCode = null;
                  });
                },
                child: const Text('SCAN AGAIN'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          isScanning = true;
        });
      }
    });
  }

  void _showMedicineNotFoundDialog(String code) {
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Medicine Not Found',
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'SCAN AGAIN',
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          isScanning = true;
                          lastScannedCode = null;
                        });
                      },
                      color: Colors.grey.shade200,
                      textColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'ADD NEW',
                      onPressed: () {
                        Navigator.pop(context, code);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          isScanning = true;
        });
      }
    });
  }

  void _showManualEntryDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Code Manually'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Barcode/QR Code',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processScannedCode(codeController.text);
            },
            child: const Text('SEARCH'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medicine'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                isTorchOn = !isTorchOn;
              });
              cameraController?.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initCamera,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Manually'),
                  ),
                ],
              ),
            )
          else if (!isCameraInitialized)
            const Center(child: CircularProgressIndicator())
          else if (cameraController != null)
            MobileScanner(
              controller: cameraController!,
              onDetect: _onDetect,
            ),
          
          if (isCameraInitialized && cameraController != null)
            IgnorePointer(
              child: Container(
                decoration: const ShapeDecoration(
                  shape: ScannerOverlayShape(),
                  color: Colors.transparent,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Align barcode within the frame',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    const scanWindowSize = 250.0;
    final scanWindow = Rect.fromLTWH(
      (rect.width - scanWindowSize) / 2,
      (rect.height - scanWindowSize) / 2 - 40,
      scanWindowSize,
      scanWindowSize,
    );

    path.addRect(scanWindow);
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()..color = Colors.black54;
    canvas.drawPath(getOuterPath(rect), paint);

    const scanWindowSize = 250.0;
    final left = (rect.width - scanWindowSize) / 2;
    final top = (rect.height - scanWindowSize) / 2 - 40;
    final right = left + scanWindowSize;
    final bottom = top + scanWindowSize;

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawLine(Offset(left, top), Offset(left + 40, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + 40), cornerPaint);
    canvas.drawLine(Offset(right - 40, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + 40), cornerPaint);
    canvas.drawLine(Offset(left, bottom - 40), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + 40, bottom), cornerPaint);
    canvas.drawLine(Offset(right - 40, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom - 40), Offset(right, bottom), cornerPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}