import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _title(),
          style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: darkBlue),
          ),
        ],
      ),

      body: _page(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGrey,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pedal_bike_outlined),
            activeIcon: Icon(Icons.pedal_bike_rounded),
            label: 'Cycles',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  String _title() {
    switch (selectedIndex) {
      case 1:
        return 'Bookings';
      case 2:
        return 'Students';
      case 3:
        return 'Cycles';
      default:
        return 'Admin Dashboard';
    }
  }

  // ============================================================
  // PAGE
  // ============================================================

  Widget _page() {
    switch (selectedIndex) {
      case 1:
        return _bookingsPage();

      case 2:
        return _studentsPage();

      case 3:
        return _cyclesPage();

      default:
        return _dashboardPage();
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _dashboardPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('bookings').snapshots(),
      builder: (context, bookingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('students').snapshots(),
          builder: (context, studentSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('cycles').snapshots(),
              builder: (context, cycleSnapshot) {
                final bookingCount = bookingSnapshot.data?.docs.length ?? 0;

                final studentCount = studentSnapshot.data?.docs.length ?? 0;

                final cycleCount = cycleSnapshot.data?.docs.length ?? 0;

                final availableCycles =
                    cycleSnapshot.data?.docs.where((doc) {
                      return _isCycleAvailable(doc.data());
                    }).length ??
                    0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome, Admin 👋',
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Manage RentaCycle from one place.',
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // STAT CARDS
                      // ==================================================
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              Icons.receipt_long_rounded,
                              'Bookings',
                              bookingCount.toString(),
                              primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              Icons.people_rounded,
                              'Students',
                              studentCount.toString(),
                              Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              Icons.pedal_bike_rounded,
                              'Cycles',
                              cycleCount.toString(),
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              Icons.check_circle_rounded,
                              'Available',
                              availableCycles.toString(),
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Admin Controls',
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _control(
                        Icons.book_online_rounded,
                        'Booking Management',
                        'View student bookings.',
                        () {
                          setState(() {
                            selectedIndex = 1;
                          });
                        },
                      ),

                      _control(
                        Icons.person_search_rounded,
                        'Student Management',
                        'View registered students.',
                        () {
                          setState(() {
                            selectedIndex = 2;
                          });
                        },
                      ),

                      _control(
                        Icons.pedal_bike_rounded,
                        'Cycle Management',
                        'View cycle availability.',
                        () {
                          setState(() {
                            selectedIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOOKINGS
  // ============================================================

  Widget _bookingsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('bookings')
          .orderBy('startTime')
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
            'Please check your Firestore data and permissions.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _messageCard(
            Icons.receipt_long_outlined,
            'No bookings found',
            'Student bookings will appear here automatically.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Text(
              '${docs.length} Booking${docs.length == 1 ? '' : 's'}',
              style: const TextStyle(color: textGrey, fontSize: 14),
            ),

            const SizedBox(height: 15),

            ...docs.map((doc) => _adminBookingCard(doc.id, doc.data())),
          ],
        );
      },
    );
  }

  Widget _adminBookingCard(String bookingId, Map<String, dynamic> data) {
    final cycleName = data['cycleName']?.toString() ?? 'Cycle';

    final location = data['cycleLocation']?.toString() ?? 'Campus';

    final userId = data['userId']?.toString() ?? 'Unknown';

    final status = data['status']?.toString() ?? 'Unknown';

    final start = _formatTime(data['startTime']);

    final end = _formatTime(data['endTime']);

    final statusLower = status.toLowerCase();

    final Color statusColor = statusLower == 'active'
        ? Colors.green
        : statusLower == 'upcoming'
        ? primaryBlue
        : textGrey;

    return Container(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: primaryBlue,
                  size: 27,
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
                      location,
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: primaryBlue,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  '$start → $end',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Student ID: $userId',
            style: const TextStyle(color: textGrey, fontSize: 10),
          ),

          const SizedBox(height: 3),

          Text(
            'Booking ID: ${bookingId.length > 12 ? bookingId.substring(0, 12) : bookingId}',
            style: const TextStyle(color: textGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENTS
  // ============================================================

  Widget _studentsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            Icons.error_outline_rounded,
            'Unable to load students',
            'Please check your Firestore permissions.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _messageCard(
            Icons.people_outline_rounded,
            'No students found',
            'Registered student details will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Text(
              '${docs.length} Student${docs.length == 1 ? '' : 's'}',
              style: const TextStyle(color: textGrey, fontSize: 14),
            ),

            const SizedBox(height: 15),

            ...docs.map((doc) => _studentCard(doc.id, doc.data())),
          ],
        );
      },
    );
  }

  Widget _studentCard(String studentId, Map<String, dynamic> data) {
    final name = data['fullName']?.toString() ?? 'Student';

    final email = data['email']?.toString() ?? 'No email';

    final admission = data['admissionNumber']?.toString() ?? 'Not available';

    final department = data['department']?.toString() ?? 'Not available';

    final batch = data['batch']?.toString() ?? 'Not available';

    return Container(
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
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_rounded,
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
                      name,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _studentDetailRow(
            Icons.badge_outlined,
            'Admission Number',
            admission,
          ),

          _studentDetailRow(Icons.school_outlined, 'Department', department),

          _studentDetailRow(Icons.calendar_today_outlined, 'Batch', batch),

          const SizedBox(height: 4),

          Text(
            'Student ID: $studentId',
            style: const TextStyle(color: textGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _studentDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: textGrey, size: 17),

          const SizedBox(width: 8),

          Text(
            '$title: ',
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textDark, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CYCLES
  // ============================================================

  Widget _cyclesPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            Icons.error_outline_rounded,
            'Unable to load cycles',
            'Please check your Firestore permissions.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _messageCard(
            Icons.pedal_bike_outlined,
            'No cycles found',
            'Add cycles to Firestore and they will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Text(
              '${docs.length} Cycle${docs.length == 1 ? '' : 's'}',
              style: const TextStyle(color: textGrey, fontSize: 14),
            ),

            const SizedBox(height: 15),

            ...docs.map((doc) => _cycleAdminCard(doc.id, doc.data())),
          ],
        );
      },
    );
  }

  Widget _cycleAdminCard(String cycleId, Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? 'Cycle';

    final type = data['type']?.toString() ?? 'Standard';

    final location = data['location']?.toString() ?? 'Campus';

    final rating = data['rating']?.toString() ?? '4.5';

    final available = _isCycleAvailable(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.pedal_bike_rounded,
              color: primaryBlue,
              size: 29,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  type,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  location,
                  style: const TextStyle(color: textGrey, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  'Rating: $rating',
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: available
                  ? const Color(0xFFEAF8EF)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              available ? 'Available' : 'Unavailable',
              style: TextStyle(
                color: available ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isCycleAvailable(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';

    if (status == 'maintenance' ||
        status == 'under maintenance' ||
        status == 'repair' ||
        status == 'unavailable') {
      return false;
    }

    if (data['available'] is bool) {
      return data['available'] == true;
    }

    return status == 'available';
  }

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    if (value is DateTime) {
      final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;

      final minute = value.minute.toString().padLeft(2, '0');

      final period = value.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return '--:--';
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(height: 13),

          Text(
            value,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(title, style: const TextStyle(color: textGrey, fontSize: 11)),
        ],
      ),
    );
  }

  // ============================================================
  // CONTROL
  // ============================================================

  Widget _control(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: textGrey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: textGrey),
      ),
    );
  }

  // ============================================================
  // MESSAGE CARD
  // ============================================================

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primaryBlue, size: 42),

              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }
}
