import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class BarcodeService {
  // Singleton pattern
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  /// Scans a barcode and returns the barcode value
  /// Returns null if scanning was canceled or an error occurred
  Future<String?> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666', 
        'Abbrechen', 
        true, 
        ScanMode.BARCODE,
      );

      // Return null if scanning was canceled
      if (barcodeScanRes == '-1') {
        return null;
      }

      return barcodeScanRes;
    } on PlatformException {
      return null;
    } on Exception {
      return null;
    }
  }

  /// Validates if the provided code is a valid EAN code
  /// EAN-13, EAN-8, UPC-A (12 digits), UPC-E (8 digits)
  bool isValidEAN(String code) {
    if (code.isEmpty) return false;
    
    // Check if the string is a valid number
    if (int.tryParse(code) == null) return false;
    
    // Check for valid lengths for different barcode types
    if (![8, 12, 13].contains(code.length)) return false;
    
    // Implement checksum validation for EAN-13
    if (code.length == 13) {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(code[i]);
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      int checksum = (10 - (sum % 10)) % 10;
      return int.parse(code[12]) == checksum;
    }
    
    // For simplicity, we're accepting other formats without checksum validation
    return true;
  }
}