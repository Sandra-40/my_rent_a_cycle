import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'landing_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final Color green = const Color(0xFF1B8A5A);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      _buildBookingsPage(),
      _buildTrackPage(),
      _buildMaintenancePage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: Text(
          selectedIndex == 0
              ? 'Admin Dashboard'
              : [
                  'Home',
                  'Bookings',
                  'Track',
                  'Maintenance',
                  'Profile',
                ][selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE2F2E8),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Maintenance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load dashboard data.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cycles = snapshot.data?.docs ?? [];

        int available = 0;
        int inUse = 0;
        int maintenance = 0;

        for (final cycle in cycles) {
          final status = (cycle.data()['status'] ?? '')
              .toString()
              .toLowerCase();

          if (status == 'available') {
            available++;
          } else if (status == 'in_use') {
            inUse++;
          } else if (status == 'maintenance' || status == 'under maintenance') {
            maintenance++;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, bookingSnapshot) {
            final totalBookings = bookingSnapshot.data?.docs.length ?? 0;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF244B36),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here is an overview of your RentaCycle system.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fleet Overview',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _statCard(
                      'Total Cycles',
                      cycles.length.toString(),
                      Icons.pedal_bike,
                      const Color(0xFF2878B5),
                    ),
                    _statCard(
                      'Available',
                      available.toString(),
                      Icons.check_circle_outline,
                      green,
                    ),
                    _statCard(
                      'Currently In Use',
                      inUse.toString(),
                      Icons.directions_bike,
                      Colors.orange,
                    ),
                    _statCard(
                      'Maintenance',
                      maintenance.toString(),
                      Icons.build_circle_outlined,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _statCard(
                  'Total Bookings',
                  totalBookings.toString(),
                  Icons.calendar_month,
                  const Color(0xFF7456A6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Overview',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _quickAction(
                  Icons.calendar_month,
                  'Manage Bookings',
                  'View student booking records',
                  () => setState(() => selectedIndex = 1),
                ),
                _quickAction(
                  Icons.location_on,
                  'Track Cycles',
                  'View recorded cycle locations',
                  () => setState(() => selectedIndex = 2),
                ),
                _quickAction(
                  Icons.build,
                  'Maintenance',
                  'Check damage reports and repairs',
                  () => setState(() => selectedIndex = 3),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 27),
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: green, size: 27),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBookingsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load bookings.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data();
            final userId = data['userId']?.toString() ?? '';

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: userId.isEmpty
                  ? null
                  : FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
              builder: (context, userSnapshot) {
                final studentData = userSnapshot.data?.data();

                final studentName =
                    studentData?['fullName']?.toString() ??
                    'Name not available';

                final admissionNo =
                    studentData?['admissionNo']?.toString() ?? 'Not available';

                final email = data['email']?.toString() ?? 'Not available';

                final cycleName =
                    data['cycleName']?.toString() ?? 'Campus Cycle';

                final status = data['status']?.toString() ?? 'Unknown';

                final duration =
                    data['duration']?.toString() ??
                    '${data['durationMinutes'] ?? 'Not available'} minutes';

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE2F2E8),
                              child: Icon(Icons.pedal_bike, color: green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cycleName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(status.toUpperCase()),
                              backgroundColor:
                                  status.toLowerCase() == 'completed'
                                  ? Colors.green.shade100
                                  : status.toLowerCase() == 'active'
                                  ? Colors.orange.shade100
                                  : const Color(0xFFE2F2E8),
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        const Text(
                          'Student Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _bookingInfo(
                          Icons.person_outline,
                          'Student Name',
                          userSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Loading...'
                              : studentName,
                        ),
                        _bookingInfo(
                          Icons.badge_outlined,
                          'Admission Number',
                          admissionNo,
                        ),
                        _bookingInfo(Icons.email_outlined, 'Email', email),
                        const Divider(height: 25),
                        const Text(
                          'Booking Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _bookingInfo(
                          Icons.calendar_today_outlined,
                          'Start Date',
                          _formatBookingDate(data['startTime']),
                        ),
                        _bookingInfo(
                          Icons.event_available_outlined,
                          'Return Date',
                          _formatBookingDate(data['returnTime']),
                        ),
                        _bookingInfo(
                          Icons.timer_outlined,
                          'Duration',
                          duration,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _bookingInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: green),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookingDate(dynamic value) {
    if (value == null) return 'Not available';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTrackPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load cycle information.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cycles = snapshot.data?.docs ?? [];

        if (cycles.isEmpty) {
          return const Center(child: Text('No cycles found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Cycle Location Information',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page displays the location information saved for each cycle.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            ...cycles.map((cycle) {
              final data = cycle.data();

              return Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: Icon(Icons.location_on, color: green),
                  title: Text(data['name'] ?? 'Campus Cycle'),
                  subtitle: Text(
                    'Location: ${data['location'] ?? 'Not recorded'}\nStatus: ${data['status'] ?? 'Unknown'}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMaintenancePage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('damage_reports')
          .orderBy('reportedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load damage reports.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data?.docs ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 55, color: Colors.green),
                SizedBox(height: 12),
                Text('No damage reports found.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final data = report.data();

            final status = (data['status'] ?? 'open').toString();
            final isOpen = status.toLowerCase() == 'open';
            final photoUrl = data['photoUrl']?.toString();

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (data['cycleName'] ?? 'Campus Cycle').toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(status.toUpperCase()),
                          backgroundColor: isOpen
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Damage: ${data['damageType'] ?? 'Not specified'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (data['description'] ?? 'No description provided.')
                          .toString(),
                    ),
                    if (photoUrl != null && photoUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photoUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Unable to load damage photo.');
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (isOpen)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final firestore = FirebaseFirestore.instance;
                              final cycleId = data['cycleId']?.toString();

                              if (cycleId == null || cycleId.isEmpty) {
                                throw Exception('Cycle ID is missing.');
                              }

                              final batch = firestore.batch();

                              batch.update(report.reference, {
                                'status': 'repaired',
                                'repairedAt': FieldValue.serverTimestamp(),
                              });

                              batch.update(
                                firestore.collection('cycles').doc(cycleId),
                                {'status': 'available'},
                              );

                              await batch.commit();

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cycle marked as repaired.'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Mark as Repaired'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFFE2F2E8),
          child: Icon(
            Icons.admin_panel_settings,
            size: 45,
            color: Color(0xFF1B8A5A),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'Administrator',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            user?.email ?? 'Admin account',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 28),
        Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.email_outlined, color: Color(0xFF1B8A5A)),
            title: const Text('Email Address'),
            subtitle: Text(user?.email ?? 'Not available'),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }
}
