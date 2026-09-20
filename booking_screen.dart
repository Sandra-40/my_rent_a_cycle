import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final String cycleId;
  final String cycleName;
  final String cycleType;
  final String cycleLocation;

  const BookingScreen({
    super.key,
    required this.cycleId,
    required this.cycleName,
    required this.cycleType,
    required this.cycleLocation,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  TimeOfDay? startTime;
  TimeOfDay? returnTime;

  bool isBooking = false;

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      startTime = picked;
      returnTime = null;
    });
  }

  Future<void> _selectReturnTime() async {
    if (startTime == null) {
      _showMessage('Please select a start time first.');
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: startTime!,
    );

    if (picked == null) return;

    final start = startTime!.hour * 60 + startTime!.minute;
    final end = picked.hour * 60 + picked.minute;

    int difference = end - start;

    if (difference < 0) {
      difference += 1440;
    }

    if (difference == 0) {
      _showMessage('Return time must be after start time.');
      return;
    }

    if (difference > 120) {
      _showMessage('A booking cannot be longer than 2 hours.');
      return;
    }

    setState(() {
      returnTime = picked;
    });
  }

  int _durationMinutes() {
    if (startTime == null || returnTime == null) {
      return 0;
    }

    final start = startTime!.hour * 60 + startTime!.minute;
    final end = returnTime!.hour * 60 + returnTime!.minute;

    int difference = end - start;

    if (difference < 0) {
      difference += 1440;
    }

    return difference;
  }

  String _durationText() {
    final minutes = _durationMinutes();

    if (minutes == 0) return 'Not selected';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours hr $mins min';
    }

    if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$mins min';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return time.format(context);
  }

  DateTime _todayWithTime(TimeOfDay time) {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<bool> _hasOverlappingBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final newStart = _todayWithTime(startTime!);
    DateTime newEnd = _todayWithTime(returnTime!);

    if (!newEnd.isAfter(newStart)) {
      newEnd = newEnd.add(const Duration(days: 1));
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('cycleId', isEqualTo: widget.cycleId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = data['status']?.toString().toLowerCase() ?? '';

      if (status != 'active' && status != 'upcoming') {
        continue;
      }

      final existingStart = _readDate(data['startDateTime']);
      final existingEnd = _readDate(data['endDateTime']);

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final overlaps =
          newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Future<void> _confirmBooking() async {
    if (startTime == null) {
      _showMessage('Please select a start time.');
      return;
    }

    if (returnTime == null) {
      _showMessage('Please select a return time.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login before booking.');
      return;
    }

    final duration = _durationMinutes();

    if (duration <= 0 || duration > 120) {
      _showMessage('Booking duration must be between 1 and 120 minutes.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Booking',
            style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogRow('Cycle', widget.cycleName),
              const SizedBox(height: 10),
              _dialogRow('Type', widget.cycleType),
              const SizedBox(height: 10),
              _dialogRow('Location', widget.cycleLocation),
              const SizedBox(height: 10),
              _dialogRow('Start', _formatTime(startTime)),
              const SizedBox(height: 10),
              _dialogRow('Return', _formatTime(returnTime)),
              const SizedBox(height: 10),
              _dialogRow('Duration', _durationText()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: textGrey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isBooking = true;
    });

    try {
      final overlapping = await _hasOverlappingBooking();

      if (overlapping) {
        _showMessage('This cycle is already booked during that time.');
        return;
      }

      final startDateTime = _todayWithTime(startTime!);

      DateTime endDateTime = _todayWithTime(returnTime!);

      if (!endDateTime.isAfter(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final now = DateTime.now();

      final status = startDateTime.isAfter(now) ? 'upcoming' : 'active';

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',

        'cycleId': widget.cycleId,
        'cycleName': widget.cycleName,
        'cycleType': widget.cycleType,
        'cycleLocation': widget.cycleLocation,

        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),

        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),

        'startTimeText': _formatTime(startTime),
        'endTimeText': _formatTime(returnTime),

        'durationMinutes': duration,
        'duration': _durationText(),

        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Could not create booking: $e');
    } finally {
      if (mounted) {
        setState(() {
          isBooking = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeCard({
    required String title,
    required String time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: borderBlue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 18),
                ),
                const Spacer(),
                const Icon(Icons.edit_rounded, color: textGrey, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: textGrey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
        Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: darkBlue),
        ),
        title: const Text(
          'Book a Cycle',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pedal_bike_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cycleName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${widget.cycleType} • ${widget.cycleLocation}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Ride Time',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Choose when you start and return your cycle.',
                style: TextStyle(color: textGrey, fontSize: 13),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _timeCard(
                      title: 'Start Time',
                      time: _formatTime(startTime),
                      icon: Icons.login_rounded,
                      onTap: _selectStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeCard(
                      title: 'Return Time',
                      time: _formatTime(returnTime),
                      icon: Icons.logout_rounded,
                      onTap: _selectReturnTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: borderBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: primaryBlue),
                    const SizedBox(width: 10),
                    const Text(
                      'Ride duration',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _durationText(),
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: primaryBlue),
                        SizedBox(width: 8),
                        Text(
                          'Booking Summary',
                          style: TextStyle(
                            color: darkBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _summaryRow('Cycle', widget.cycleName),
                    const Divider(height: 22),
                    _summaryRow('Type', widget.cycleType),
                    const Divider(height: 22),
                    _summaryRow('Location', widget.cycleLocation),
                    const Divider(height: 22),
                    _summaryRow('Start', _formatTime(startTime)),
                    const Divider(height: 22),
                    _summaryRow('Return', _formatTime(returnTime)),
                    const Divider(height: 22),
                    _summaryRow('Duration', _durationText()),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isBooking ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded),
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
                  'Bookings are limited to a maximum of 2 hours.',
                  style: TextStyle(color: textGrey, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
