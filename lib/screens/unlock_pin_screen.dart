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
  final Color green = const Color(0xFF1B8A5A);
  final TextEditingController pinController = TextEditingController();

  bool physicalUnlockConfirmed = false;
  bool isLoading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Unlock Cycle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(Icons.lock_open_rounded, color: green, size: 55),
              ),

              const SizedBox(height: 22),

              const Text(
                'Your Cycle is Verified!',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter the unlock PIN for ${widget.cycleName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 35),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter 4-Digit PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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
                  fontSize: 25,
                  letterSpacing: 15,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE1E8E2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE1E8E2)),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE1E8E2)),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: green,
                  value: physicalUnlockConfirmed,
                  onChanged: (value) {
                    setState(() {
                      physicalUnlockConfirmed = value ?? false;
                    });
                  },
                  title: const Text(
                    'Physical Unlock Confirmation',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'I confirm that the cycle is physically unlocked and ready to use.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Start Ride',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
