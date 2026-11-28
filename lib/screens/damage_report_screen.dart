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
  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

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
        backgroundColor: primary,
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
            color: softTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cyan, size: 22),
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
                  color: darkTeal,
                ),
              ),
              const SizedBox(height: 3),
              const Text(' ', style: TextStyle(fontSize: 1)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: mutedText),
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
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: darkTeal,
          ),
        ),
        backgroundColor: surface,
        foregroundColor: darkTeal,
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF23717B),
                      Color(0xFF314B51),
                      Color(0xFF12B2C1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.20),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
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
                            color: cyan,
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
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDamage,
                          hint: const Text(
                            'Select damage type',
                            style: TextStyle(color: mutedText),
                          ),
                          isExpanded: true,
                          dropdownColor: surface,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: cyan,
                          ),
                          items: damageTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(color: darkTeal),
                              ),
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
                      style: const TextStyle(color: darkTeal, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Describe the problem with the cycle...',
                        hintStyle: const TextStyle(
                          color: mutedText,
                          fontSize: 13,
                        ),
                        counterStyle: const TextStyle(color: mutedText),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: cyan, width: 1.5),
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
                          border: Border.all(color: borderColor),
                        ),
                        child: damagePhoto == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 55,
                                    width: 55,
                                    decoration: BoxDecoration(
                                      color: softTeal,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                      color: cyan,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tap to capture a photo',
                                    style: TextStyle(
                                      color: darkTeal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Photo is optional',
                                    style: TextStyle(
                                      color: mutedText,
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
                          style: TextButton.styleFrom(foregroundColor: cyan),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF514735),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF786747)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFFFD27A),
                      size: 22,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: TextStyle(
                              color: Color(0xFFFFD27A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Submitting this report will automatically end your current ride and mark the cycle as under maintenance.',
                            style: TextStyle(
                              color: Color(0xFFFFE8B8),
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
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.6),
                    elevation: 1,
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

              const Center(
                child: Text(
                  'Thank you for helping us maintain our cycles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
