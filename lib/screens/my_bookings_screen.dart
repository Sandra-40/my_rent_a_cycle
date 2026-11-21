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
  final Color green = const Color(0xFF1B8A5A);

  String selectedTab = 'Upcoming';

  final List<String> tabs = ['Active', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your bookings.'))
          : SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Rides',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Booking category tabs
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
                                color: isSelected ? green : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? green
                                      : const Color(0xFFE3EAE5),
                                ),
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
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
                            child: Text('Unable to load your bookings.'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5EBE6)),
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
                  color: const Color(0xFFE8F4EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.pedal_bike_rounded, color: green, size: 31),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycleName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (data['duration'] ?? 'Cycle booking').toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 15),

          _detailRow(
            Icons.calendar_today_outlined,
            'Date',
            startDate == null ? '—' : _formatDate(startDate),
          ),
          const SizedBox(height: 11),
          _detailRow(
            Icons.access_time_rounded,
            'Time',
            startDate == null || endDate == null
                ? '—'
                : '${_formatTime(startDate)} - ${_formatTime(endDate)}',
          ),
          const SizedBox(height: 11),
          _detailRow(Icons.timer_outlined, 'Duration', duration),
          const SizedBox(height: 11),
          _detailRow(Icons.payments_outlined, 'Price', 'FREE'),

          if (!isCompleted) ...[
            const SizedBox(height: 17),
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
                ),
                label: Text(isActive ? 'End Ride' : 'Scan QR to Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
    final Color background;

    if (normalized == 'active') {
      color = Colors.blue.shade700;
      background = Colors.blue.shade50;
    } else if (normalized == 'completed') {
      color = green;
      background = const Color(0xFFE6F5EA);
    } else {
      color = Colors.orange.shade800;
      background = const Color(0xFFFFF2DD);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
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
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              'No $selectedTab bookings yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your cycle bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
