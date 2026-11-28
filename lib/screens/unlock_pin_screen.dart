import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'ride_screen.dart';

class UnlockPinScreen extends StatefulWidget {
  final String bookingId;
  final String cycleId;
  final String cycleName;

  const UnlockPinScreen({
    super.key,
    required this.bookingId,
    required this.cycleId,
    required this.cycleName,
  });

  @override
  State<UnlockPinScreen> createState() => _UnlockPinScreenState();
}

class _UnlockPinScreenState extends State<UnlockPinScreen> {
  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  final TextEditingController pinController = TextEditingController();

  bool physicalUnlockConfirmed = false;
  bool isLoading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: surface));
  }

  Future<void> startRide() async {
    final enteredPin = pinController.text.trim();

    if (enteredPin.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(enteredPin)) {
      showMessage('Please enter a valid 4-digit PIN.');
      return;
    }

    if (!physicalUnlockConfirmed) {
      showMessage('Please confirm that the cycle is physically unlocked.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final cycleRef = firestore.collection('cycles').doc(widget.cycleId);
      final bookingRef = firestore.collection('bookings').doc(widget.bookingId);

      await firestore.runTransaction((transaction) async {
        final cycleSnapshot = await transaction.get(cycleRef);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!cycleSnapshot.exists || !bookingSnapshot.exists) {
          throw Exception('Booking or cycle not found.');
        }

        final cycleData = cycleSnapshot.data()!;
        final bookingData = bookingSnapshot.data()!;

        final storedPin = (cycleData['unlockPin'] ?? '').toString();

        if (storedPin.isEmpty || enteredPin != storedPin) {
          throw Exception('Incorrect unlock PIN.');
        }

        if (bookingData['status'] != 'upcoming') {
          throw Exception('This booking cannot be started.');
        }

        if (cycleData['status'] != 'available') {
          throw Exception('This cycle is not currently available.');
        }

        transaction.update(bookingRef, {
          'status': 'active',
          'rideStartedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(cycleRef, {'status': 'in_use'});
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideScreen(
            bookingId: widget.bookingId,
            cycleId: widget.cycleId,
            cycleName: widget.cycleName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Unlock Cycle',
          style: TextStyle(
            color: darkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: surface,
        foregroundColor: darkTeal,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 25),

              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [softTeal, surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: cyan,
                  size: 55,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Your Cycle is Verified!',
                style: TextStyle(
                  color: darkTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter the unlock PIN for ${widget.cycleName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText, fontSize: 14),
              ),

              const SizedBox(height: 35),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter 4-Digit PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkTeal,
                  fontSize: 25,
                  letterSpacing: 15,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: const TextStyle(
                    color: mutedText,
                    letterSpacing: 15,
                  ),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: cyan, width: 1.8),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: cyan,
                  checkColor: background,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  value: physicalUnlockConfirmed,
                  onChanged: (value) {
                    setState(() {
                      physicalUnlockConfirmed = value ?? false;
                    });
                  },
                  title: const Text(
                    'Physical Unlock Confirmation',
                    style: TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'I confirm that the cycle is physically unlocked and ready to use.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 53,
                child: ElevatedButton(
                  onPressed: isLoading ? null : startRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pedal_bike_rounded, size: 21),
                            SizedBox(width: 9),
                            Text(
                              'Start Ride',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: cyan),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
