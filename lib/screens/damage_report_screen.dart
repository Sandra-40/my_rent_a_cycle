import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DamageReportScreen extends StatefulWidget {
  final String bookingId;
  final String cycleId;
  final String cycleName;

  const DamageReportScreen({
    super.key,
    required this.bookingId,
    required this.cycleId,
    required this.cycleName,
  });

  @override
  State<DamageReportScreen> createState() => _DamageReportScreenState();
}

class _DamageReportScreenState extends State<DamageReportScreen> {
  final Color green = const Color(0xFF1B8A5A);
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  final List<String> damageTypes = [
    'Flat Tire',
    'Broken Chain',
    'Brakes Not Working',
    'Seat Damage',
    'Handlebar Issue',
    'Other',
  ];

  String? selectedDamage;
  File? damagePhoto;
  bool isSubmitting = false;

  Future<void> capturePhoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        setState(() {
          damagePhoto = File(image.path);
        });
      }
    } catch (e) {
      showMessage('Unable to capture photo: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> uploadDamagePhoto() async {
    final reference = FirebaseStorage.instance
        .ref()
        .child('damage_reports')
        .child(widget.bookingId)
        .child('damage_photo.jpg');

    await reference.putFile(damagePhoto!);
    return await reference.getDownloadURL();
  }

  Future<void> submitReport() async {
    if (selectedDamage == null) {
      showMessage('Please select a damage category.');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showMessage('Please describe the damage.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String? photoUrl;

      if (damagePhoto != null) {
        photoUrl = await uploadDamagePhoto();
      }

      final firestore = FirebaseFirestore.instance;

      final reportRef = firestore.collection('damage_reports').doc();

      final bookingRef = firestore.collection('bookings').doc(widget.bookingId);

      final cycleRef = firestore.collection('cycles').doc(widget.cycleId);

      final batch = firestore.batch();

      batch.set(reportRef, {
        'bookingId': widget.bookingId,
        'cycleId': widget.cycleId,
        'cycleName': widget.cycleName,
        'damageType': selectedDamage,
        'description': descriptionController.text.trim(),
        'photoUrl': photoUrl,
        'status': 'open',
        'reportedAt': FieldValue.serverTimestamp(),
      });

      batch.update(bookingRef, {
        'status': 'completed',
        'rideEndedAt': FieldValue.serverTimestamp(),
        'endedDueToDamage': true,
      });

      batch.update(cycleRef, {'status': 'maintenance'});

      await batch.commit();

      if (!mounted) return;

      showMessage('Damage report submitted successfully!');

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      showMessage('Failed to submit report: $e');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Report Cycle Damage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report a Problem',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.cycleName,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              const Text(
                'Damage Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDamage,
                    hint: const Text('Select damage type'),
                    isExpanded: true,
                    items: damageTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              selectedDamage = value;
                            });
                          },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: descriptionController,
                maxLines: 5,
                maxLength: 500,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Describe the problem with the cycle...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Damage Photo (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: isSubmitting ? null : capturePhoto,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: damagePhoto == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 38,
                              color: green,
                            ),
                            const SizedBox(height: 10),
                            const Text('Tap to capture damage photo'),
                            const SizedBox(height: 5),
                            const Text(
                              'You can skip this step',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            damagePhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),

              if (damagePhoto != null)
                TextButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          setState(() => damagePhoto = null);
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Damage Report',
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
