import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

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

  String? selectedCycle;
  TimeOfDay? startTime;
  TimeOfDay? returnTime;

  bool isBooking = false;

  final List<Map<String, dynamic>> cycles = [
    {'name': 'Cycle 01', 'location': 'Main Campus'},
    {'name': 'Cycle 02', 'location': 'Library Block'},
    {'name': 'Cycle 03', 'location': 'Hostel Block'},
    {'name': 'Cycle 04', 'location': 'Academic Block'},
  ];

  // ------------------------------------------------------------
  // SELECT START TIME
  // ------------------------------------------------------------

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
        returnTime = null;
      });
    }
  }

  // ------------------------------------------------------------
  // SELECT RETURN TIME
  // ------------------------------------------------------------

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

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final returnMinutes = picked.hour * 60 + picked.minute;

    int difference = returnMinutes - startMinutes;

    if (difference < 0) {
      difference += 24 * 60;
    }

    // Maximum booking time = 2 hours
    if (difference > 120) {
      _showMessage(
        'Return time cannot be more than 2 hours after the start time.',
      );
      return;
    }

    if (difference == 0) {
      _showMessage('Return time must be after the start time.');
      return;
    }

    setState(() {
      returnTime = picked;
    });
  }

  // ------------------------------------------------------------
  // FORMAT TIME
  // ------------------------------------------------------------

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return '--:--';
    }

    return time.format(context);
  }

  // ------------------------------------------------------------
  // CALCULATE DURATION
  // ------------------------------------------------------------

  String _calculateDuration() {
    if (startTime == null || returnTime == null) {
      return 'Not selected';
    }

    final start = startTime!.hour * 60 + startTime!.minute;

    final end = returnTime!.hour * 60 + returnTime!.minute;

    int difference = end - start;

    if (difference < 0) {
      difference += 24 * 60;
    }

    final hours = difference ~/ 60;
    final minutes = difference % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    }

    if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$minutes min';
  }

  // ------------------------------------------------------------
  // CONFIRM BOOKING + FIREBASE
  // ------------------------------------------------------------

  Future<void> _confirmBooking() async {
    if (selectedCycle == null) {
      _showMessage('Please select a cycle.');
      return;
    }

    if (startTime == null) {
      _showMessage('Please select a start time.');
      return;
    }

    if (returnTime == null) {
      _showMessage('Please select a return time.');
      return;
    }

    // Check Firebase login
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login before booking a cycle.');
      return;
    }

    // Calculate duration
    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final returnMinutes = returnTime!.hour * 60 + returnTime!.minute;

    int difference = returnMinutes - startMinutes;

    if (difference < 0) {
      difference += 24 * 60;
    }

    // Safety check: maximum 2 hours
    if (difference > 120) {
      _showMessage('A booking cannot be longer than 2 hours.');
      return;
    }

    try {
      // Show confirmation dialog first
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
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _dialogRow('Cycle', selectedCycle!),

                const SizedBox(height: 10),

                _dialogRow('Start', _formatTime(startTime)),

                const SizedBox(height: 10),

                _dialogRow('Return', _formatTime(returnTime)),

                const SizedBox(height: 10),

                _dialogRow('Duration', _calculateDuration()),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },

                child: const Text('Cancel', style: TextStyle(color: textGrey)),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },

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

      if (confirmed != true) {
        return;
      }

      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,

        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        },
      );

      // -----------------------------------------------------
      // SAVE BOOKING TO FIRESTORE
      // -----------------------------------------------------

      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'userId': user.uid,
            'email': user.email,

            'cycle': selectedCycle,

            'startTime': _formatTime(startTime),
            'returnTime': _formatTime(returnTime),

            'durationMinutes': difference,
            'duration': _calculateDuration(),

            'status': 'active',

            'createdAt': FieldValue.serverTimestamp(),
          });

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking confirmed! ID: ${bookingRef.id}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear selected booking
      setState(() {
        selectedCycle = null;
        startTime = null;
        returnTime = null;
      });
    } catch (e) {
      // Close loading dialog if it is open
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save booking: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SHOW MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ------------------------------------------------------------
  // DIALOG ROW
  // ------------------------------------------------------------

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),

        Text(
          value,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

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
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF173B6C)],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(22),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.pedal_bike_rounded,
                      color: Colors.white,
                      size: 42,
                    ),

                    SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Ready to ride?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Choose a cycle and your ride time.',
                            style: TextStyle(
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

              // --------------------------------------------------
              // CYCLE SELECTION
              // --------------------------------------------------
              const Text(
                'Select a Cycle',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...cycles.map((cycle) {
                final selected = selectedCycle == cycle['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCycle = cycle['name'];
                    });
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    margin: const EdgeInsets.only(bottom: 12),

                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(17),

                      border: Border.all(
                        color: selected ? primaryBlue : const Color(0xFFE2E8F0),

                        width: selected ? 2 : 1,
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,

                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: const Icon(
                            Icons.pedal_bike_rounded,
                            color: primaryBlue,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                cycle['name'],
                                style: const TextStyle(
                                  color: textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: textGrey,
                                    size: 15,
                                  ),

                                  const SizedBox(width: 4),

                                  Text(
                                    cycle['location'],
                                    style: const TextStyle(
                                      color: textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 8,
                                  ),

                                  SizedBox(width: 5),

                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,

                          color: selected ? primaryBlue : Colors.grey.shade400,

                          size: 25,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // TIME SELECTION
              // --------------------------------------------------
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

              // --------------------------------------------------
              // DURATION
              // --------------------------------------------------
              Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 15,
                ),

                decoration: BoxDecoration(
                  color: lightBlue,

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: borderBlue),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),

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
                      _calculateDuration(),
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // BOOKING SUMMARY
              // --------------------------------------------------
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
                        Icon(
                          Icons.receipt_long_rounded,
                          color: primaryBlue,
                          size: 21,
                        ),

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

                    _summaryRow('Cycle', selectedCycle ?? 'Not selected'),

                    const Divider(height: 22),

                    _summaryRow('Start', _formatTime(startTime)),

                    const Divider(height: 22),

                    _summaryRow('Return', _formatTime(returnTime)),

                    const Divider(height: 22),

                    _summaryRow('Duration', _calculateDuration()),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // CONFIRM BUTTON
              // --------------------------------------------------
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

  // ------------------------------------------------------------
  // TIME CARD
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SUMMARY ROW
  // ------------------------------------------------------------

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
}
