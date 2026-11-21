import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class RideVerificationScreen extends StatefulWidget {
  final String bookingId;
  final String cycleId;
  final String cycleName;

  const RideVerificationScreen({
    super.key,
    required this.bookingId,
    required this.cycleId,
    required this.cycleName,
  });

  @override
  State<RideVerificationScreen> createState() => _RideVerificationScreenState();
}

class _RideVerificationScreenState extends State<RideVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  File? rearLockPhoto;
  File? parkedCyclePhoto;

  Position? currentPosition;
  bool isLocked = false;
  bool isLoading = false;

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable location services.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      Position position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> takePhoto(bool isRearLock) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );

      if (image == null || !mounted) return;

      setState(() {
        if (isRearLock) {
          rearLockPhoto = File(image.path);
        } else {
          parkedCyclePhoto = File(image.path);
        }
      });
    } catch (e) {
      showMessage('Unable to capture photo: $e');
    }
  }

  Future<String> uploadPhoto(File file, String photoName) async {
    final reference = FirebaseStorage.instance
        .ref()
        .child('ride_verifications')
        .child(widget.bookingId)
        .child('$photoName.jpg');

    await reference.putFile(file);
    return await reference.getDownloadURL();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> completeRide() async {
    if (rearLockPhoto == null ||
        parkedCyclePhoto == null ||
        currentPosition == null ||
        !isLocked) {
      showMessage('Complete all verification steps before ending the ride.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final rearLockUrl = await uploadPhoto(rearLockPhoto!, 'rear_lock');

      final parkedCycleUrl = await uploadPhoto(
        parkedCyclePhoto!,
        'parked_cycle',
      );

      final firestore = FirebaseFirestore.instance;

      final verificationRef = firestore.collection('ride_verifications').doc();

      final bookingRef = firestore.collection('bookings').doc(widget.bookingId);

      final cycleRef = firestore.collection('cycles').doc(widget.cycleId);

      final batch = firestore.batch();

      batch.set(verificationRef, {
        'bookingId': widget.bookingId,
        'cycleId': widget.cycleId,
        'cycleName': widget.cycleName,
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
        'rearLockPhoto': rearLockUrl,
        'parkedCyclePhoto': parkedCycleUrl,
        'isLocked': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      batch.update(bookingRef, {
        'status': 'completed',
        'rideEndedAt': FieldValue.serverTimestamp(),
      });

      batch.update(cycleRef, {'status': 'available'});

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      showMessage('Ride verification failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget photoCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: const Color(0xFF1B8A5A), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    image == null ? 'Tap to capture photo' : 'Photo captured',
                    style: TextStyle(
                      color: image == null ? Colors.grey : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image == null ? Icons.camera_alt_outlined : Icons.check_circle,
              color: const Color(0xFF1B8A5A),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'End Ride Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete Your Ride',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.cycleName,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              const Text(
                '1. Location Verification',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF1B8A5A),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentPosition == null
                            ? 'Location not verified'
                            : 'Location captured successfully',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : getLocation,
                      child: Text(
                        currentPosition == null ? 'Get Location' : 'Refresh',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                '2. Capture Photos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              photoCard(
                title: 'Rear Lock Photo',
                image: rearLockPhoto,
                icon: Icons.lock_outline,
                onTap: () => takePhoto(true),
              ),

              const SizedBox(height: 12),

              photoCard(
                title: 'Parked Cycle Photo',
                image: parkedCyclePhoto,
                icon: Icons.pedal_bike,
                onTap: () => takePhoto(false),
              ),

              const SizedBox(height: 24),

              const Text(
                '3. Lock Confirmation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CheckboxListTile(
                  value: isLocked,
                  activeColor: const Color(0xFF1B8A5A),
                  title: const Text(
                    'I confirm that the cycle is properly locked.',
                    style: TextStyle(fontSize: 14),
                  ),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            isLocked = value ?? false;
                          });
                        },
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : completeRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A5A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Ride',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
