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
  int maintenanceTab = 0;

  final Color green = const Color(0xFF176B50);
  final Color lightGreen = const Color(0xFFE8F3EC);
  final Color background = const Color(0xFFF5F8F6);
  final Color darkText = const Color(0xFF26352D);
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Admin Dashboard',
      'Bookings',
      'Fleet Tracking',
      'Maintenance',
      'Admin Profile',
    ];

    final pages = [
      _buildHomePage(),
      _buildBookingsPage(),
      _buildTrackPage(),
      _buildMaintenancePage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          const SizedBox(width: 5),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: lightGreen,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded),
            label: 'Maintenance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState('Unable to load fleet information.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }

        final cycles = snapshot.data?.docs ?? [];
        int available = 0;
        int booked = 0;
        int inUse = 0;
        int maintenance = 0;

        for (final cycle in cycles) {
          final status = (cycle.data()['status'] ?? '')
              .toString()
              .toLowerCase();

          if (status == 'available') {
            available++;
          } else if (status == 'booked' || status == 'upcoming') {
            booked++;
          } else if (status == 'in_use') {
            inUse++;
          } else if (status == 'maintenance' || status == 'under maintenance') {
            maintenance++;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore.collection('bookings').snapshots(),
          builder: (context, bookingSnapshot) {
            final totalBookings = bookingSnapshot.data?.docs.length ?? 0;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [green, const Color(0xFF104D3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            color: Color(0xFFFFD27D),
                            size: 23,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage your campus bicycle fleet from one place.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pedal_bike_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cycles.length} cycles registered',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _sectionTitle(
                  'Fleet Overview',
                  subtitle: 'Current status of your cycles',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Total Cycles',
                            cycles.length.toString(),
                            Icons.pedal_bike,
                            const Color(0xFF2878B5),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Available',
                            available.toString(),
                            Icons.check_circle_outline,
                            green,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Booked',
                            booked.toString(),
                            Icons.calendar_month,
                            const Color(0xFF7456A6),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'In Use',
                            inUse.toString(),
                            Icons.directions_bike,
                            Colors.orange,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Maintenance',
                            maintenance.toString(),
                            Icons.build_circle_outlined,
                            Colors.red,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Total Bookings',
                            totalBookings.toString(),
                            Icons.receipt_long,
                            const Color(0xFF2878B5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _sectionTitle(
                  'Quick Actions',
                  subtitle: 'Access important admin sections',
                ),
                const SizedBox(height: 13),
                _quickAction(
                  Icons.calendar_month_rounded,
                  'Manage Bookings',
                  'View all student booking records',
                  () => setState(() => selectedIndex = 1),
                ),
                _quickAction(
                  Icons.location_on_rounded,
                  'Track Cycles',
                  'View fleet location information',
                  () => setState(() => selectedIndex = 2),
                ),
                _quickAction(
                  Icons.build_rounded,
                  'Maintenance',
                  'Review damage reports and repairs',
                  () => setState(() => selectedIndex = 3),
                ),
                const SizedBox(height: 15),
              ],
            );
          },
        );
      },
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
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBookingsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState('Unable to load bookings.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }

        final bookings = snapshot.data?.docs ?? [];

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
          children: [
            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [green, const Color(0xFF12543E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Monitor and review student cycle bookings.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '${bookings.length} Total Bookings',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _sectionTitle(
              'All Bookings',
              subtitle: 'Latest student booking records',
            ),
            const SizedBox(height: 15),
            if (bookings.isEmpty)
              _emptyState(
                Icons.calendar_month_outlined,
                'No bookings yet',
                'Student bookings will appear here.',
              ),
            ...bookings.map((booking) {
              final data = booking.data();
              final userId = data['userId']?.toString() ?? '';

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: userId.isEmpty
                    ? null
                    : firestore.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  final student = userSnapshot.data?.data();
                  final name =
                      student?['fullName']?.toString() ?? 'Name not available';
                  final admission =
                      student?['admissionNo']?.toString() ?? 'Not available';
                  final email = data['email']?.toString() ?? 'Not available';
                  final cycle = data['cycleName']?.toString() ?? 'Campus Cycle';
                  final status = data['status']?.toString() ?? 'Unknown';
                  final duration =
                      data['duration']?.toString() ??
                      '${data['durationMinutes'] ?? 'Not available'} minutes';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: const Color(0xFFE6ECE7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 10,
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
                              height: 47,
                              width: 47,
                              decoration: BoxDecoration(
                                color: lightGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.pedal_bike_rounded,
                                color: green,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cycle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Booking ID: ${booking.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 17),
                        const Divider(height: 1),
                        const SizedBox(height: 15),
                        _detailHeading(
                          Icons.person_outline_rounded,
                          'STUDENT DETAILS',
                        ),
                        const SizedBox(height: 13),
                        _infoRow(
                          Icons.person_outline,
                          'Name',
                          userSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Loading...'
                              : name,
                        ),
                        _infoRow(
                          Icons.badge_outlined,
                          'Admission No.',
                          admission,
                        ),
                        _infoRow(Icons.email_outlined, 'Email', email),
                        const SizedBox(height: 6),
                        const Divider(height: 1),
                        const SizedBox(height: 15),
                        _detailHeading(
                          Icons.calendar_month_outlined,
                          'BOOKING DETAILS',
                        ),
                        const SizedBox(height: 13),
                        _infoRow(
                          Icons.login_rounded,
                          'Start Time',
                          _formatDate(data['startTime']),
                        ),
                        _infoRow(
                          Icons.logout_rounded,
                          'Return Time',
                          _formatDate(data['returnTime']),
                        ),
                        _infoRow(Icons.timer_outlined, 'Duration', duration),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _detailHeading(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: green, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
            color: Color(0xFF718078),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState('Unable to load cycle information.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }

        final cycles = snapshot.data?.docs ?? [];
        int available = 0;
        int booked = 0;
        int inUse = 0;
        int maintenance = 0;

        for (final cycle in cycles) {
          final status = (cycle.data()['status'] ?? '')
              .toString()
              .toLowerCase();

          if (status == 'available') {
            available++;
          } else if (status == 'booked' || status == 'upcoming') {
            booked++;
          } else if (status == 'in_use') {
            inUse++;
          } else if (status == 'maintenance' || status == 'under maintenance') {
            maintenance++;
          }
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: _sectionTitle(
                    'Fleet Tracking',
                    subtitle: 'Monitor your registered campus cycles',
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {}),
                  icon: Icon(Icons.refresh_rounded, color: green),
                  tooltip: 'Refresh tracking information',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.satellite_alt, color: Colors.orange, size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Integration Pending',
                          style: TextStyle(
                            color: Color(0xFF9A5B00),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Live cycle locations will be available after GPS setup.',
                          style: TextStyle(
                            color: Color(0xFF9A5B00),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle(
              'Fleet Location Map',
              subtitle: 'Map preview for future GPS integration',
            ),
            const SizedBox(height: 12),
            Container(
              height: 215,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1EC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCE7DF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    left: -35,
                    top: 65,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                        width: 450,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 55,
                    top: -35,
                    child: Transform.rotate(
                      angle: 0.7,
                      child: Container(
                        width: 25,
                        height: 330,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    bottom: 45,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 300,
                        height: 22,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 18,
                    child: _mapMarker(Icons.pedal_bike, green),
                  ),
                  Positioned(
                    right: 45,
                    top: 55,
                    child: _mapMarker(Icons.location_on, Colors.orange),
                  ),
                  Positioned(
                    left: 105,
                    bottom: 25,
                    child: _mapMarker(Icons.pedal_bike, green),
                  ),
                  Positioned(
                    right: 90,
                    bottom: 20,
                    child: _mapMarker(Icons.location_on, Colors.blue),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, color: green, size: 29),
                          const SizedBox(height: 7),
                          const Text(
                            'Map Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF26352D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Live coordinates unavailable',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.orange, size: 8),
                          SizedBox(width: 5),
                          Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            _sectionTitle(
              'Fleet Status',
              subtitle: 'Current cycle status from Firestore',
            ),
            const SizedBox(height: 13),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _smallStatusCard('Available', available, green),
                _smallStatusCard('Booked', booked, const Color(0xFF2878B5)),
                _smallStatusCard('In Use', inUse, Colors.orange),
                _smallStatusCard('Maintenance', maintenance, Colors.red),
              ],
            ),
            const SizedBox(height: 23),
            _sectionTitle(
              'Cycle Information',
              subtitle: '${cycles.length} registered cycles',
            ),
            const SizedBox(height: 13),
            if (cycles.isEmpty)
              _emptyState(
                Icons.pedal_bike,
                'No cycles found',
                'Registered cycles will appear here.',
              ),
            ...cycles.map((cycle) {
              final data = cycle.data();
              final status = data['status']?.toString() ?? 'Unknown';
              final location =
                  data['parkingAddress']?.toString() ??
                  data['location']?.toString() ??
                  'Not recorded';
              final battery = data['batteryPercent'] ?? data['batteryLevel'];
              final speed = data['speed'];
              final imei = data['imei'] ?? data['IMEI'];
              final gps =
                  data['gpsStatus'] ??
                  (data['isOnline'] == null
                      ? null
                      : (data['isOnline'] == true ? 'Online' : 'Offline'));

              final batteryValue = battery == null
                  ? 'Not available'
                  : battery.toString().contains('%')
                  ? battery.toString()
                  : '${battery.toString()}%';

              final gpsText = gps?.toString() ?? 'Not available';
              final isOnline =
                  gpsText.toLowerCase() == 'online' ||
                  gpsText.toLowerCase() == 'on' ||
                  gpsText.toLowerCase() == 'true';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.pedal_bike, color: green, size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name']?.toString() ?? 'Campus Cycle',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${cycle.id}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 17),
                    const Divider(height: 1),
                    const SizedBox(height: 15),
                    _trackingInfoTile(
                      Icons.location_on_outlined,
                      'Parking Location',
                      location,
                    ),
                    _trackingInfoTile(
                      Icons.memory,
                      'IMEI Number',
                      imei?.toString() ?? 'Not available',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: _trackingMetric(
                            Icons.battery_std,
                            'Battery',
                            batteryValue,
                            green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _trackingMetric(
                            Icons.speed,
                            'Speed',
                            speed == null ? 'Not available' : '$speed km/h',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: 18,
                            color: isOnline ? green : Colors.orange,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'GPS Connection',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            gpsText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _smallStatusCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title == 'Available'
                  ? Icons.check_circle_outline
                  : title == 'Booked'
                  ? Icons.calendar_month
                  : title == 'In Use'
                  ? Icons.directions_bike
                  : Icons.build_circle_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapMarker(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }

  Widget _trackingInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF26352D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingMetric(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF26352D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenancePage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('damage_reports')
          .orderBy('reportedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState('Unable to load damage reports.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }

        final reports = snapshot.data?.docs ?? [];

        final openReports = reports.where((report) {
          final status = (report.data()['status'] ?? 'open')
              .toString()
              .toLowerCase();
          return status == 'open';
        }).toList();

        final resolvedReports = reports.where((report) {
          final status = (report.data()['status'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'repaired' || status == 'resolved';
        }).toList();

        final displayedReports = maintenanceTab == 0
            ? openReports
            : resolvedReports;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [green, const Color(0xFF104D3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.13),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maintenance Center',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Monitor damage reports and manage cycle repairs.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.build_circle_outlined,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _maintenanceSummary(
                          'Open Issues',
                          openReports.length.toString(),
                          Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _maintenanceSummary(
                          'Resolved',
                          resolvedReports.length.toString(),
                          Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _sectionTitle(
              'Repair Records',
              subtitle: 'Review and manage reported cycle damage',
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEFED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _maintenanceTabButton('Open Issues', openReports.length, 0),
                  _maintenanceTabButton('Resolved', resolvedReports.length, 1),
                ],
              ),
            ),
            const SizedBox(height: 17),
            if (displayedReports.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 35),
                decoration: _cardDecoration(),
                child: _emptyState(
                  maintenanceTab == 0
                      ? Icons.check_circle_outline
                      : Icons.build_circle_outlined,
                  maintenanceTab == 0 ? 'All Clear!' : 'No Resolved Reports',
                  maintenanceTab == 0
                      ? 'There are no pending maintenance issues.'
                      : 'Completed repair records will appear here.',
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Text(
                  '${displayedReports.length} ${maintenanceTab == 0 ? 'pending' : 'completed'} report${displayedReports.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...displayedReports.map((report) => _maintenanceCard(report)),
            ],
          ],
        );
      },
    );
  }

  Widget _maintenanceSummary(String title, String count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceTabButton(String title, int count, int index) {
    final selected = maintenanceTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => maintenanceTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : darkText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _maintenanceCard(QueryDocumentSnapshot<Map<String, dynamic>> report) {
    final data = report.data();
    final status = (data['status'] ?? 'open').toString();
    final isOpen = status.toLowerCase() == 'open';
    final photoUrl = data['photoUrl']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6ECE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFFFFF1E5)
                      : const Color(0xFFE8F3EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isOpen
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: isOpen ? Colors.orange : green,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['cycleName']?.toString() ?? 'Campus Cycle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Damage Report',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.build_outlined,
                  'Issue',
                  data['damageType']?.toString() ?? 'Not specified',
                ),
                _infoRow(
                  Icons.tag,
                  'Cycle ID',
                  data['cycleId']?.toString() ?? 'Not available',
                ),
                _infoRow(
                  Icons.access_time,
                  'Reported',
                  _formatDate(data['reportedAt']),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Issue Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26352D),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data['description']?.toString() ?? 'No description provided.',
            style: const TextStyle(
              color: Color(0xFF65736B),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Attached Damage Photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26352D),
              ),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                photoUrl,
                height: 185,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 185,
                    alignment: Alignment.center,
                    color: const Color(0xFFF1F4F2),
                    child: CircularProgressIndicator(
                      color: green,
                      value: progress.expectedTotalBytes == null
                          ? null
                          : progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: Colors.grey),
                        SizedBox(height: 5),
                        Text(
                          'Unable to load damage photo.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (!isOpen) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: green, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Repaired on ${_formatDate(data['repairedAt'])}',
                      style: TextStyle(
                        color: green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton.icon(
                onPressed: () => _markAsRepaired(report),
                icon: const Icon(Icons.check_circle_outline, size: 19),
                label: const Text(
                  'Mark as Repaired',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 0,
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

  Future<void> _markAsRepaired(
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) async {
    try {
      final data = report.data();
      final cycleId = data['cycleId']?.toString();

      if (cycleId == null || cycleId.isEmpty) {
        throw Exception('Cycle ID is missing.');
      }

      final batch = firestore.batch();

      batch.update(report.reference, {
        'status': 'repaired',
        'repairedAt': FieldValue.serverTimestamp(),
      });

      batch.update(firestore.collection('cycles').doc(cycleId), {
        'status': 'available',
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle marked as repaired.'),
          backgroundColor: Color(0xFF176B50),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Not available';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [green, const Color(0xFF104D3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.14),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 43,
                backgroundColor: Colors.white,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: green,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Admin Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _sectionTitle(
          'Account Information',
          subtitle: 'Administrator account details',
        ),
        const SizedBox(height: 14),
        _profileInfoCard(Icons.email_outlined, 'Email Address', email),
        _profileInfoCard(
          Icons.admin_panel_settings_outlined,
          'Role',
          'Administrator',
        ),
        _profileInfoCard(
          Icons.verified_user_outlined,
          'Account Status',
          user == null ? 'Not signed in' : 'Signed in',
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 51,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCEAEA),
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'RentaCycle Admin Panel',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: green, size: 21),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: green),
          const SizedBox(width: 9),
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF26352D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final value = status.toLowerCase();

    Color color;
    Color foreground;

    if (value == 'available' ||
        value == 'completed' ||
        value == 'repaired' ||
        value == 'resolved') {
      color = Colors.green.shade100;
      foreground = Colors.green.shade800;
    } else if (value == 'in_use' || value == 'active') {
      color = Colors.orange.shade100;
      foreground = Colors.orange.shade900;
    } else if (value == 'maintenance' || value == 'open') {
      color = Colors.red.shade100;
      foreground = Colors.red.shade800;
    } else {
      color = Colors.blue.shade50;
      foreground = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8EEEA)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return Center(child: CircularProgressIndicator(color: green));
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 53, color: Colors.grey.shade400),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
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
