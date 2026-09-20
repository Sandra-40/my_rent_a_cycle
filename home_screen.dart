import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedTab = 0;

  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Standard',
    'Sport',
    'Electric',
    'Mountain',
    'Foldable',
  ];

  // ============================================================
  // USER
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';

    return 'Good Evening';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _studentStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection('students').doc(user.uid).snapshots();
  }

  // ============================================================
  // CYCLE HELPERS
  // ============================================================

  bool _isAvailable(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';

    if (status == 'maintenance' ||
        status == 'under maintenance' ||
        status == 'repair') {
      return false;
    }

    if (data['available'] is bool) {
      return data['available'] == true;
    }

    return status == 'available';
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (selectedFilter == 'All') {
      return true;
    }

    return data['type']?.toString().toLowerCase() ==
        selectedFilter.toLowerCase();
  }

  // ============================================================
  // BOOKING
  // ============================================================

  void _openBooking(Map<String, dynamic> cycle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          cycleId: cycle['id'].toString(),
          cycleName: cycle['name']?.toString() ?? 'Cycle',
          cycleType: cycle['type']?.toString() ?? 'Standard',
          cycleLocation: cycle['location']?.toString() ?? 'Campus',
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'RentaCycle',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedTab = 2;
              });
            },
            icon: const Icon(Icons.person_outline_rounded, color: darkBlue),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: IndexedStack(
        index: _selectedTab,
        children: [_homeTab(), _bookingsTab(), _profileTab()],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),

        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedTab,

            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },

            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,

            selectedItemColor: primaryBlue,
            unselectedItemColor: textGrey,

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOME TAB
  // ============================================================

  Widget _homeTab() {
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _studentStream(),

        builder: (context, studentSnapshot) {
          String firstName = 'Student';

          if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
            final data = studentSnapshot.data!.data();

            final fullName = data?['fullName']?.toString().trim() ?? '';

            if (fullName.isNotEmpty) {
              firstName = fullName.split(' ').first;
            }
          } else {
            final user = _auth.currentUser;

            if (user?.displayName != null &&
                user!.displayName!.trim().isNotEmpty) {
              firstName = user.displayName!.trim().split(' ').first;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '${_getGreeting()}, $firstName 👋',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Find a cycle and start your ride.',
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),

                const SizedBox(height: 22),

                // READY TO RIDE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, darkBlue],
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Choose an available cycle below.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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
                  'Browse Cycles',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // FILTERS
                SizedBox(
                  height: 42,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,

                    itemCount: filters.length,

                    separatorBuilder: (_, __) => const SizedBox(width: 8),

                    itemBuilder: (context, index) {
                      final filter = filters[index];

                      final selected = selectedFilter == filter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: selected ? primaryBlue : Colors.white,

                            borderRadius: BorderRadius.circular(22),

                            border: Border.all(
                              color: selected
                                  ? primaryBlue
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),

                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selected ? Colors.white : textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // FIRESTORE CYCLES
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore.collection('cycles').snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(color: primaryBlue),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _emptyCard(
                        Icons.error_outline_rounded,
                        'Unable to load cycles',
                        'Please check your Firebase connection.',
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    final cycles = docs.where((doc) {
                      final data = doc.data();

                      return _matchesFilter(data) && _isAvailable(data);
                    }).toList();

                    if (cycles.isEmpty) {
                      return _emptyCard(
                        Icons.pedal_bike_outlined,
                        'No cycles available',
                        'Please check again later.',
                      );
                    }

                    return Column(
                      children: cycles.map((doc) {
                        final data = doc.data();

                        final cycle = {
                          'id': doc.id,
                          'name': data['name'] ?? 'Cycle',
                          'type': data['type'] ?? 'Standard',
                          'location': data['location'] ?? 'Campus',
                          'rating': data['rating'] ?? '4.5',
                        };

                        return _cycleCard(cycle);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // INFO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderBlue),
                  ),

                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: primaryBlue,
                        size: 22,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Bookings are limited to a maximum of 2 hours. Completed rides automatically disappear from My Bookings.',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CYCLE CARD
  // ============================================================

  Widget _cycleCard(Map<String, dynamic> cycle) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: primaryBlue,
                  size: 31,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      cycle['name'].toString(),

                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      cycle['type'].toString(),

                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

                        Expanded(
                          child: Text(
                            cycle['location'].toString(),
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,

                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 17,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        cycle['rating'].toString(),
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EF),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 45,

            child: ElevatedButton(
              onPressed: () => _openBooking(cycle),

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),

              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.calendar_month_rounded, size: 18),

                  SizedBox(width: 8),

                  Text(
                    'Book This Cycle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKINGS TAB
  // ============================================================

  Widget _bookingsTab() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in again.'));
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            return _emptyCard(
              Icons.error_outline_rounded,
              'Unable to load bookings',
              'Please check your Firebase connection.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final activeBookings = docs.where((doc) {
            final status = doc.data()['status']?.toString().toLowerCase() ?? '';

            return status == 'active';
          }).toList();

          final upcomingBookings = docs.where((doc) {
            final status = doc.data()['status']?.toString().toLowerCase() ?? '';

            return status == 'upcoming';
          }).toList();

          if (activeBookings.isEmpty && upcomingBookings.isEmpty) {
            return _emptyCard(
              Icons.receipt_long_outlined,
              'No Active or Upcoming Rides',
              'Your current bookings will appear here.',
            );
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
                  'Track your current and upcoming rides.',
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),

                const SizedBox(height: 25),

                if (activeBookings.isNotEmpty) ...[
                  _bookingSectionTitle(
                    'Active Ride',
                    Icons.pedal_bike_rounded,
                    Colors.green,
                  ),

                  const SizedBox(height: 10),

                  ...activeBookings.map(
                    (doc) => _bookingCard(doc.id, doc.data()),
                  ),

                  const SizedBox(height: 15),
                ],

                if (upcomingBookings.isNotEmpty) ...[
                  _bookingSectionTitle(
                    'Upcoming Rides',
                    Icons.schedule_rounded,
                    primaryBlue,
                  ),

                  const SizedBox(height: 10),

                  ...upcomingBookings.map(
                    (doc) => _bookingCard(doc.id, doc.data()),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bookingSectionTitle(String title, IconData icon, Color color) {
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

  Widget _bookingCard(String bookingId, Map<String, dynamic> data) {
    final cycleName = data['cycleName']?.toString() ?? 'Cycle';

    final cycleLocation = data['cycleLocation']?.toString() ?? 'Campus';

    final status = data['status']?.toString() ?? 'active';

    final startTime = _formatTime(data['startTime']);

    final endTime = _formatTime(data['endTime']);

    final isActive = status.toLowerCase() == 'active';

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

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: textGrey,
                          size: 15,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            cycleLocation,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _statusChip(status, statusColor),
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

            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: primaryBlue,
                  size: 19,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '$startTime → $endTime',
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Booking ID: ${bookingId.length > 10 ? bookingId.substring(0, 10) : bookingId}',
            style: const TextStyle(color: textGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    final text = status.isEmpty
        ? 'Unknown'
        : status.substring(0, 1).toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE TAB
  // ============================================================

  Widget _profileTab() {
    final user = _auth.currentUser;

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _studentStream(),

        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          final name =
              data?['fullName']?.toString() ?? user?.displayName ?? 'Student';

          final email =
              data?['email']?.toString() ?? user?.email ?? 'Not available';

          final admission =
              data?['admissionNumber']?.toString() ?? 'Not available';

          final department = data?['department']?.toString() ?? 'Not available';

          final batch = data?['batch']?.toString() ?? 'Not available';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                const SizedBox(height: 15),

                Container(
                  width: 90,
                  height: 90,

                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: const Icon(
                    Icons.person_rounded,
                    color: primaryBlue,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  name,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  style: const TextStyle(color: textGrey, fontSize: 13),
                ),

                const SizedBox(height: 25),

                _profileInfo(
                  Icons.badge_outlined,
                  'Admission Number',
                  admission,
                ),

                _profileInfo(Icons.school_outlined, 'Department', department),

                _profileInfo(Icons.calendar_today_outlined, 'Batch', batch),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: OutlinedButton.icon(
                    onPressed: _logout,

                    icon: const Icon(Icons.logout_rounded, color: Colors.red),

                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileInfo(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,

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
          value,
          style: const TextStyle(color: textGrey, fontSize: 12),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),

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

            style: const TextStyle(color: textGrey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

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
}
