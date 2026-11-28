import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';
import 'ride_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const Color green = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  String selectedTab = 'Upcoming';

  final List<String> tabs = ['Active', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkTeal,
            fontSize: 20,
          ),
        ),
        backgroundColor: background,
        foregroundColor: darkTeal,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view your bookings.',
                style: TextStyle(color: darkTeal),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Container(
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.pedal_bike_rounded, color: cyan, size: 32),
                          SizedBox(height: 12),
                          Text(
                            'Your Rides',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Keep track of all your cycle bookings.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: tabs.map((tab) {
                        final isSelected = selectedTab == tab;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedTab = tab);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? green : surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? cyan : borderColor,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cyan.withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: darkTeal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Unable to load your bookings.',
                              style: TextStyle(color: darkTeal),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: cyan),
                          );
                        }

                        final bookings =
                            snapshot.data?.docs.where((doc) {
                              final status = (doc.data()['status'] ?? '')
                                  .toString()
                                  .toLowerCase();

                              return status == selectedTab.toLowerCase();
                            }).toList() ??
                            [];

                        bookings.sort((a, b) {
                          final aTime = a.data()['startTime'];
                          final bTime = b.data()['startTime'];

                          final aDate = aTime is Timestamp
                              ? aTime.toDate()
                              : DateTime(2000);
                          final bDate = bTime is Timestamp
                              ? bTime.toDate()
                              : DateTime(2000);

                          return aDate.compareTo(bDate);
                        });

                        if (bookings.isEmpty) {
                          return _emptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final doc = bookings[index];
                            return _bookingCard(doc.id, doc.data());
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _bookingCard(String bookingId, Map<String, dynamic> data) {
    final cycleName = (data['cycleName'] ?? 'Campus Cycle').toString();

    final start = data['startTime'];
    final end = data['returnTime'];

    final startDate = start is Timestamp ? start.toDate() : null;
    final endDate = end is Timestamp ? end.toDate() : null;

    final duration = (data['duration'] ?? '—').toString();
    final status = (data['status'] ?? 'upcoming').toString();

    final isActive = status.toLowerCase() == 'active';
    final isCompleted = status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: softTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: cyan,
                  size: 31,
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
                        color: darkTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (data['duration'] ?? 'Cycle booking').toString(),
                      style: const TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          _detailRow(
            Icons.calendar_today_outlined,
            'Date',
            startDate == null ? '—' : _formatDate(startDate),
          ),
          const SizedBox(height: 13),
          _detailRow(
            Icons.access_time_rounded,
            'Time',
            startDate == null || endDate == null
                ? '—'
                : '${_formatTime(startDate)} - ${_formatTime(endDate)}',
          ),
          const SizedBox(height: 13),
          _detailRow(Icons.timer_outlined, 'Duration', duration),
          const SizedBox(height: 13),
          _detailRow(Icons.payments_outlined, 'Price', 'FREE'),
          if (!isCompleted) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final cycleId = (data['cycleId'] ?? '').toString();

                  if (cycleId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cycle information is missing for this booking.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (isActive) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideScreen(
                          bookingId: bookingId,
                          cycleId: cycleId,
                          cycleName: cycleName,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRScannerScreen(
                          bookingId: bookingId,
                          cycleId: cycleId,
                          cycleName: cycleName,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isActive
                      ? Icons.stop_circle_outlined
                      : Icons.qr_code_scanner_rounded,
                  size: 20,
                ),
                label: Text(isActive ? 'End Ride' : 'Scan QR to Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 1,
                  shadowColor: cyan.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final Color color;
    final Color badgeBackground;

    if (normalized == 'active') {
      color = const Color(0xFF65C5E8);
      badgeBackground = const Color(0xFF294F60);
    } else if (normalized == 'completed') {
      color = const Color(0xFF7BD5B0);
      badgeBackground = const Color(0xFF294F4A);
    } else {
      color = const Color(0xFFFFD27A);
      badgeBackground = const Color(0xFF554A36);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: badgeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: cyan, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: mutedText, fontSize: 13)),
        const Spacer(),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: softTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 45,
                color: cyan,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No $selectedTab bookings yet',
              style: const TextStyle(
                color: darkTeal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your cycle bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
