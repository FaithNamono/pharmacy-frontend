import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import the two implementations
import 'qr_scanner_mobile.dart';
import 'qr_scanner_web.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use mobile scanner only on actual mobile devices (iOS/Android)
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      return const QRScannerMobile();
    } 
    // For web and other platforms (Windows, macOS, Linux), use web version
    else {
      return const QRScannerWeb();
    }
  }
}