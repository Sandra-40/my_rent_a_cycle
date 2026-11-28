import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'unlock_pin_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String bookingId;
  final String cycleId;
  final String cycleName;

  const QRScannerScreen({
    super.key,
    required this.bookingId,
    required this.cycleId,
    required this.cycleName,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  static const Color green = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  final MobileScannerController scannerController = MobileScannerController();

  bool isProcessing = false;
  bool isVerified = false;
  String? errorMessage;

  Future<void> verifyQRCode(String scannedValue) async {
    if (isProcessing || isVerified) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please log in again.');
      }

      final cycleSnapshot = await FirebaseFirestore.instance
          .collection('cycles')
          .doc(widget.cycleId)
          .get();

      if (!cycleSnapshot.exists) {
        throw Exception('Cycle not found.');
      }

      final cycleData = cycleSnapshot.data()!;

      final expectedQR = (cycleData['qrCode'] ?? '').toString();

      if (expectedQR.isEmpty || scannedValue.trim() != expectedQR.trim()) {
        throw Exception('QR code does not match this cycle.');
      }

      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!bookingSnapshot.exists) {
        throw Exception('Booking not found.');
      }

      final bookingData = bookingSnapshot.data()!;

      if (bookingData['userId'] != user.uid ||
          bookingData['cycleId'] != widget.cycleId) {
        throw Exception('This booking does not belong to you.');
      }

      if (bookingData['status'] != 'upcoming') {
        throw Exception('This booking is not available for scanning.');
      }

      if (!mounted) return;

      setState(() {
        isVerified = true;
      });

      await scannerController.stop();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UnlockPinScreen(
            bookingId: widget.bookingId,
            cycleId: widget.cycleId,
            cycleName: widget.cycleName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      await scannerController.start();
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Scan Cycle QR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkTeal,
            fontSize: 20,
          ),
        ),
        backgroundColor: background,
        foregroundColor: darkTeal,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded, color: cyan),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const Icon(Icons.qr_code_scanner_rounded, color: cyan, size: 38),
            const SizedBox(height: 14),
            const Text(
              'Verify Your Cycle',
              style: TextStyle(
                color: darkTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Scan the QR code attached to ${widget.cycleName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText, fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Container(
                  width: 290,
                  height: 290,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: cyan, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: cyan.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) {
                        final barcode = capture.barcodes.firstOrNull;

                        if (barcode?.rawValue != null) {
                          verifyQRCode(barcode!.rawValue!);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: cyan),
                    SizedBox(height: 10),
                    Text(
                      'Verifying QR code...',
                      style: TextStyle(color: mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF452D32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFA6A6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.center_focus_strong_rounded,
                      color: cyan,
                      size: 23,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Position the QR code inside the scanning frame.',
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkTeal,
                    side: const BorderSide(color: cyan, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
