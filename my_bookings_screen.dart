import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return _messageCard(
              Icons.error_outline_rounded,
              'Unable to load bookings',
              'Please check your Firebase connection.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final now = DateTime.now();

          final activeBookings =
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final upcomingBookings =
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          for (final doc in docs) {
            final data = doc.data();

            String status = data['status']?.toString().toLowerCase() ?? '';

            final start = _readDate(data['startDateTime']);
            final end = _readDate(data['endDateTime']);

            // Automatically determine expired rides.
            if (end != null && !end.isAfter(now)) {
              status = 'completed';
            } else if (start != null && start.isAfter(now)) {
              status = 'upcoming';
            } else if (start != null && !start.isAfter(now)) {
              status = 'active';
            }

            if (status == 'active') {
              activeBookings.add(doc);
            } else if (status == 'upcoming') {
              upcomingBookings.add(doc);
            }
          }

          activeBookings.sort(
            (a, b) => _compareDates(
              a.data()['startDateTime'],
              b.data()['startDateTime'],
            ),
          );

          upcomingBookings.sort(
            (a, b) => _compareDates(
              a.data()['startDateTime'],
              b.data()['startDateTime'],
            ),
          );

          if (activeBookings.isEmpty && upcomingBookings.isEmpty) {
            return _emptyBookings();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Bookings',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Your active and upcoming cycle rides.',
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),

                const SizedBox(height: 22),

                if (activeBookings.isNotEmpty) ...[
                  _sectionTitle(
                    'Active Ride',
                    Icons.pedal_bike_rounded,
                    Colors.green,
                  ),
                  const SizedBox(height: 10),
                  ...activeBookings.map(
                    (doc) => _bookingCard(doc.id, doc.data(), 'active'),
                  ),
                  const SizedBox(height: 20),
                ],

                if (upcomingBookings.isNotEmpty) ...[
                  _sectionTitle(
                    'Upcoming Rides',
                    Icons.schedule_rounded,
                    primaryBlue,
                  ),
                  const SizedBox(height: 10),
                  ...upcomingBookings.map(
                    (doc) => _bookingCard(doc.id, doc.data(), 'upcoming'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _compareDates(dynamic a, dynamic b) {
    final dateA = _readDate(a);
    final dateB = _readDate(b);

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;

    return dateA.compareTo(dateB);
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

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(
    String bookingId,
    Map<String, dynamic> data,
    String displayStatus,
  ) {
    final cycleName =
        data['cycleName']?.toString() ?? data['cycle']?.toString() ?? 'Cycle';

    final cycleType = data['cycleType']?.toString() ?? 'Standard';

    final location = data['cycleLocation']?.toString() ?? 'Campus';

    final start = _readDate(data['startDateTime']);

    final end = _readDate(data['endDateTime']);

    final startText = start != null
        ? _formatDateTime(start)
        : _oldTime(data['startTimeText'] ?? data['startTime']);

    final endText = end != null
        ? _formatDateTime(end)
        : _oldTime(data['endTimeText'] ?? data['endTime']);

    final isActive = displayStatus == 'active';

    final statusColor = isActive ? Colors.green : primaryBlue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: primaryBlue,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycleName,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cycleType • $location',
                      style: const TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              _statusChip(displayStatus, statusColor),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: primaryBlue,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        startText,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stop_rounded, color: textGrey, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        endText,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          Text(
            'Booking ID: ${bookingId.length > 10 ? bookingId.substring(0, 10) : bookingId}',
            style: const TextStyle(color: textGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  String _oldTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return value?.toString() ?? '--:--';
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        status == 'active' ? 'Active' : 'Upcoming',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyBookings() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, color: primaryBlue, size: 55),
            SizedBox(height: 18),
            Text(
              'No Active or Upcoming Rides',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkBlue,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your current and upcoming bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: primaryBlue, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
