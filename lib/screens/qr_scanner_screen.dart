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

      // The cycle QR value must match the value stored in Firestore.
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
      backgroundColor: const Color(0xFF101713),
      appBar: AppBar(
        title: const Text(
          'Scan Cycle QR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF101713),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            const Text(
              'Verify Your Cycle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code attached to ${widget.cycleName}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF1B8A5A),
                      width: 4,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
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

            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.white),
              ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'Position the QR code inside the scanning frame.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Cancel'),
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
