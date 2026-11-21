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
  final Color green = const Color(0xFF176B50);
  final Color background = const Color(0xFFF5F8F6);
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: green,
      ),
    );
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

  Widget sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: green, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26352D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Report Damage',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26352D),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Report a Problem',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Help us keep our cycles safe and ready for everyone.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_bike,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              widget.cycleName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                      'Damage Category',
                      'Select the issue you noticed',
                      Icons.category_outlined,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1E8E2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDamage,
                          hint: const Text('Select damage type'),
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: green,
                          ),
                          items: damageTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                      'Description',
                      'Tell us more about the problem',
                      Icons.description_outlined,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      maxLength: 500,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Describe the problem with the cycle...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E8E2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E8E2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: green, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                      'Damage Photo',
                      'Add a photo to help us understand the issue',
                      Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: isSubmitting ? null : capturePhoto,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        height: 175,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD5E2D8)),
                        ),
                        child: damagePhoto == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 35,
                                    color: green,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tap to capture a photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Photo is optional',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  damagePhoto!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    if (damagePhoto != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setState(() => damagePhoto = null);
                                },
                          icon: const Icon(Icons.delete_outline, size: 19),
                          label: const Text('Remove photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF2DDB7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB7791F),
                      size: 22,
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: TextStyle(
                              color: Color(0xFF805515),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Submitting this report will automatically end your current ride and mark the cycle as under maintenance.',
                            style: TextStyle(
                              color: Color(0xFF805515),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: green.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 19),
                            SizedBox(width: 10),
                            Text(
                              'Submit Damage Report',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Thank you for helping us maintain our cycles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
