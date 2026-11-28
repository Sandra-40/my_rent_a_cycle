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
  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

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
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: surface));
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 66,
              width: 66,
              decoration: BoxDecoration(
                color: softTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(image, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: cyan, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    image == null ? 'Tap to capture photo' : 'Photo captured',
                    style: TextStyle(
                      color: image == null ? mutedText : cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image == null ? Icons.camera_alt_outlined : Icons.check_circle,
              color: image == null ? cyan : cyan,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: softTeal,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            number,
            style: const TextStyle(color: cyan, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: darkTeal,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'End Ride Verification',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: cyan,
                      size: 34,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Complete Your Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.cycleName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Final ride verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              sectionTitle('1', 'Location Verification'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: softTeal,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: cyan,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPosition == null
                                ? 'Location not verified'
                                : 'Location captured successfully',
                            style: const TextStyle(
                              color: darkTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPosition == null
                                ? 'Verify your parking location'
                                : 'GPS location is ready',
                            style: const TextStyle(
                              color: mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : getLocation,
                      style: TextButton.styleFrom(foregroundColor: cyan),
                      child: Text(
                        currentPosition == null ? 'Get Location' : 'Refresh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              sectionTitle('2', 'Capture Photos'),
              const SizedBox(height: 12),
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

              const SizedBox(height: 26),

              sectionTitle('3', 'Lock Confirmation'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: borderColor),
                ),
                child: CheckboxListTile(
                  value: isLocked,
                  activeColor: cyan,
                  checkColor: background,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  title: const Text(
                    'I confirm that the cycle is properly locked.',
                    style: TextStyle(
                      color: darkTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : completeRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 9),
                            Text(
                              'Complete Ride',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
