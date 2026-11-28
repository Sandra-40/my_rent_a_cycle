import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final String? cycleName;

  const BookingScreen({super.key, this.cycleName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color green = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  final List<String> cycleTypes = [
    'Standard',
    'Sport',
    'Electric',
    'Mountain',
    'Foldable',
  ];

  String selectedCycle = '';
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isLoading = false;

  int get durationMinutes {
    if (startTime == null || endTime == null) return 0;

    final start = startTime!.hour * 60 + startTime!.minute;
    final end = endTime!.hour * 60 + endTime!.minute;

    return end - start;
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: cyan,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: darkTeal,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> chooseStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: cyan,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: darkTeal,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
        endTime = null;
      });
    }
  }

  Future<void> chooseEndTime() async {
    if (startTime == null) {
      showMessage('Please select a start time first.');
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime!.hour + 1) % 24,
        minute: startTime!.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: cyan,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: darkTeal,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        endTime = picked;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in to continue.');
      return;
    }

    if (selectedCycle.isEmpty ||
        selectedDate == null ||
        startTime == null ||
        endTime == null) {
      showMessage('Please complete all booking details.');
      return;
    }

    if (durationMinutes <= 0) {
      showMessage('End time must be after start time on the same day.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      final endDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        endTime!.hour,
        endTime!.minute,
      );

      final cycleQuery = await FirebaseFirestore.instance
          .collection('cycles')
          .where('name', isEqualTo: selectedCycle)
          .limit(1)
          .get();

      if (cycleQuery.docs.isEmpty) {
        showMessage('Selected cycle was not found.');
        return;
      }

      final cycleDoc = cycleQuery.docs.first;

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('cycleId', isEqualTo: cycleDoc.id)
          .get();

      for (final booking in existingBookings.docs) {
        final data = booking.data();
        final existingStatus = (data['status'] ?? '').toString().toLowerCase();

        if (existingStatus == 'cancelled' || existingStatus == 'completed') {
          continue;
        }

        final existingStart = data['startTime'];
        final existingEnd = data['returnTime'];

        if (existingStart is Timestamp && existingEnd is Timestamp) {
          final oldStart = existingStart.toDate();
          final oldEnd = existingEnd.toDate();

          final overlaps =
              startDateTime.isBefore(oldEnd) && endDateTime.isAfter(oldStart);

          if (overlaps) {
            showMessage('This cycle is already booked for that time.');
            return;
          }
        }
      }

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'email': user.email,
        'cycleId': cycleDoc.id,
        'cycleName': selectedCycle,
        'startTime': Timestamp.fromDate(startDateTime),
        'returnTime': Timestamp.fromDate(endDateTime),
        'durationMinutes': durationMinutes,
        'duration': '${durationMinutes ~/ 60}h ${durationMinutes % 60}m',
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('Booking confirmed successfully!');
      Navigator.pop(context);
    } catch (e) {
      showMessage('Booking failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedCycle = widget.cycleName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Book a Cycle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkTeal,
            fontSize: 20,
          ),
        ),
        backgroundColor: background,
        foregroundColor: darkTeal,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF23717B), Color(0xFF314B51)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pedal_bike_rounded, color: cyan, size: 34),
                    const SizedBox(height: 14),
                    const Text(
                      'Plan Your Ride',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose your cycle and preferred time slot.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _sectionTitle('Select a Cycle'),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('cycles')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: cyan),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Unable to load cycles.',
                      style: TextStyle(color: mutedText),
                    );
                  }

                  final cycles =
                      snapshot.data?.docs.where((doc) {
                        final status = (doc.data()['status'] ?? '')
                            .toString()
                            .toLowerCase();

                        return status == 'available';
                      }).toList() ??
                      [];

                  if (cycles.isEmpty) {
                    return _infoBox('No available cycles right now.');
                  }

                  if (selectedCycle.isEmpty ||
                      !cycles.any(
                        (doc) =>
                            (doc.data()['name'] ?? '').toString() ==
                            selectedCycle,
                      )) {
                    selectedCycle = (cycles.first.data()['name'] ?? '')
                        .toString();
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedCycle,
                    decoration: _inputDecoration('Choose a cycle'),
                    dropdownColor: surface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cyan,
                    ),
                    style: const TextStyle(
                      color: darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: cycles.map((doc) {
                      final name = (doc.data()['name'] ?? 'Unnamed Cycle')
                          .toString();

                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCycle = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 25),
              _sectionTitle('Booking Date'),
              const SizedBox(height: 10),
              _selectionTile(
                icon: Icons.calendar_month_rounded,
                title: selectedDate == null
                    ? 'Select booking date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                onTap: chooseDate,
              ),
              const SizedBox(height: 25),
              _sectionTitle('Choose Time'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _selectionTile(
                      icon: Icons.access_time_rounded,
                      title: formatTime(startTime),
                      subtitle: 'Start time',
                      onTap: chooseStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectionTile(
                      icon: Icons.access_time_filled_rounded,
                      title: formatTime(endTime),
                      subtitle: 'End time',
                      onTap: chooseEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _sectionTitle('Booking Summary'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Selected Cycle',
                      selectedCycle.isEmpty ? 'Not selected' : selectedCycle,
                    ),
                    const Divider(height: 22, color: borderColor),
                    _summaryRow(
                      'Date',
                      selectedDate == null
                          ? 'Not selected'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                    const Divider(height: 22, color: borderColor),
                    _summaryRow('Start', formatTime(startTime)),
                    const Divider(height: 22, color: borderColor),
                    _summaryRow('End', formatTime(endTime)),
                    const Divider(height: 22, color: borderColor),
                    _summaryRow(
                      'Duration',
                      durationMinutes > 0
                          ? '${durationMinutes ~/ 60}h ${durationMinutes % 60}m'
                          : 'Not calculated',
                    ),
                    const Divider(height: 22, color: borderColor),
                    _summaryRow('Price', 'FREE'),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: green.withValues(alpha: 0.5),
                    elevation: 2,
                    shadowColor: green.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 9),
                            Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Please check your booking details before confirming.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: darkTeal,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedText),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cyan, width: 1.5),
      ),
    );
  }

  Widget _selectionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: softTeal,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: cyan, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: mutedText, fontSize: 11),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: cyan,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: mutedText, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: darkTeal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: mutedText, fontSize: 13),
      ),
    );
  }
}
