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

  static const Color green = Color(0xFF23717B);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color surface = Color(0xFF314B51);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color darkText = Color(0xFFF1F8F8);
  static const Color mutedText = Color(0xFFB5C9CC);
  static const Color borderColor = Color(0xFF456168);

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
        backgroundColor: surface,
        foregroundColor: darkText,
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
        backgroundColor: surface,
        indicatorColor: green.withValues(alpha: 0.35),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: [
          _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
          _navItem(
            Icons.calendar_month_outlined,
            Icons.calendar_month_rounded,
            'Bookings',
          ),
          _navItem(
            Icons.location_on_outlined,
            Icons.location_on_rounded,
            'Track',
          ),
          _navItem(Icons.build_outlined, Icons.build_rounded, 'Maintenance'),
          _navItem(
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profile',
          ),
        ],
      ),
    );
  }

  NavigationDestination _navItem(
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(icon, color: mutedText),
      selectedIcon: Icon(selectedIcon, color: cyan),
      label: label,
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: mutedText, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 91),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: mutedText),
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
                    gradient: const LinearGradient(
                      colors: [green, Color(0xFF314B51)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.18),
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
                            size: 22,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
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
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 17),
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
                                fontSize: 12,
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
                            cyan,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Available',
                            available.toString(),
                            Icons.check_circle_outline,
                            cyan,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Booked',
                            booked.toString(),
                            Icons.calendar_month,
                            const Color(0xFFB69AE5),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'In Use',
                            inUse.toString(),
                            Icons.directions_bike,
                            const Color(0xFFFFB45C),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Maintenance',
                            maintenance.toString(),
                            Icons.build_circle_outlined,
                            const Color(0xFFFF8585),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Total Bookings',
                            totalBookings.toString(),
                            Icons.receipt_long,
                            cyan,
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
      color: surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: softTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cyan),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: darkText),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: mutedText),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: mutedText,
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
        if (snapshot.hasError) return _errorState('Unable to load bookings.');
        if (snapshot.connectionState == ConnectionState.waiting)
          return _loadingState();

        final bookings = snapshot.data?.docs ?? [];

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
          children: [
            _headerCard(
              'Booking Management',
              'Monitor and review student cycle bookings.',
              Icons.calendar_month_rounded,
              '${bookings.length} Total Bookings',
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
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _iconBox(Icons.pedal_bike_rounded),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cycle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: darkText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Booking ID: ${booking.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: mutedText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _divider(),
                        const SizedBox(height: 14),
                        _detailHeading(
                          Icons.person_outline_rounded,
                          'STUDENT DETAILS',
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 5),
                        _divider(),
                        const SizedBox(height: 14),
                        _detailHeading(
                          Icons.calendar_month_outlined,
                          'BOOKING DETAILS',
                        ),
                        const SizedBox(height: 12),
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
        Icon(icon, color: cyan, size: 17),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
            color: mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('cycles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _errorState('Unable to load cycle information.');
        if (snapshot.connectionState == ConnectionState.waiting)
          return _loadingState();

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
                  icon: const Icon(Icons.refresh_rounded, color: cyan),
                  tooltip: 'Refresh tracking information',
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: softTeal,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                children: [
                  Icon(Icons.satellite_alt, color: cyan, size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Integration Pending',
                          style: TextStyle(
                            color: darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Live cycle locations will be available after GPS setup.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            _sectionTitle(
              'Fleet Location Map',
              subtitle: 'Map preview for future GPS integration',
            ),
            const SizedBox(height: 12),
            _buildMapPreview(),
            const SizedBox(height: 24),
            _sectionTitle(
              'Fleet Status',
              subtitle: 'Current cycle status from Firestore',
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: columns == 2 ? 2.15 : 1.8,
                  children: [
                    _smallStatusCard('Available', available, cyan),
                    _smallStatusCard('Booked', booked, const Color(0xFFB69AE5)),
                    _smallStatusCard('In Use', inUse, const Color(0xFFFFB45C)),
                    _smallStatusCard(
                      'Maintenance',
                      maintenance,
                      const Color(0xFFFF8585),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 13),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconBox(Icons.pedal_bike_rounded),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name']?.toString() ?? 'Campus Cycle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${cycle.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mutedText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _divider(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: softTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: cyan,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Parking Location',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: darkText,
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

  Widget _buildMapPreview() {
    return Container(
      height: 205,
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
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
                height: 25,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: 55,
            top: -35,
            child: Transform.rotate(
              angle: 0.7,
              child: Container(
                width: 22,
                height: 330,
                color: Colors.white.withValues(alpha: 0.07),
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
                height: 20,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 18,
            child: _mapMarker(Icons.pedal_bike, cyan),
          ),
          Positioned(
            right: 45,
            top: 55,
            child: _mapMarker(Icons.location_on, const Color(0xFFFFB45C)),
          ),
          Positioned(
            left: 105,
            bottom: 25,
            child: _mapMarker(Icons.pedal_bike, cyan),
          ),
          Positioned(
            right: 90,
            bottom: 20,
            child: _mapMarker(Icons.location_on, cyan),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: cyan, size: 27),
                  SizedBox(height: 7),
                  Text(
                    'Map Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Live coordinates unavailable',
                    style: TextStyle(color: mutedText, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFFFFB45C), size: 8),
                  SizedBox(width: 5),
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatusCard(String title, int value, Color color) {
    final icon = title == 'Available'
        ? Icons.check_circle_outline
        : title == 'Booked'
        ? Icons.calendar_month
        : title == 'In Use'
        ? Icons.directions_bike
        : Icons.build_circle_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 10),
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
        color: surface,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildMaintenancePage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('damage_reports')
          .orderBy('reportedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _errorState('Unable to load damage reports.');
        if (snapshot.connectionState == ConnectionState.waiting)
          return _loadingState();

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
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [green, Color(0xFF314B51)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Monitor damage reports and manage cycle repairs.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 51,
                        width: 51,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.build_circle_outlined,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _maintenanceSummary(
                          'Open Issues',
                          openReports.length.toString(),
                          Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 11),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: softTeal,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  _maintenanceTabButton('Open Issues', openReports.length, 0),
                  _maintenanceTabButton('Resolved', resolvedReports.length, 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (displayedReports.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
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
                    color: mutedText,
                    fontSize: 11,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : darkText,
                    fontSize: 10,
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isOpen ? const Color(0xFF604A37) : softTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOpen
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: isOpen ? const Color(0xFFFFB45C) : cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['cycleName']?.toString() ?? 'Campus Cycle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Damage Report',
                      style: TextStyle(color: mutedText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 15),
          _divider(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softTeal,
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
          const SizedBox(height: 15),
          const Text(
            'Issue Description',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data['description']?.toString() ?? 'No description provided.',
            style: const TextStyle(color: mutedText, fontSize: 12, height: 1.6),
          ),
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              'Attached Damage Photo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: softTeal,
                    child: CircularProgressIndicator(
                      color: cyan,
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
                      color: softTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: mutedText),
                        SizedBox(height: 5),
                        Text(
                          'Unable to load damage photo.',
                          style: TextStyle(color: mutedText, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (!isOpen) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: softTeal,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: cyan, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Repaired on ${_formatDate(data['repairedAt'])}',
                      style: const TextStyle(
                        color: cyan,
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
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _markAsRepaired(report),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Mark as Repaired',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
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
          backgroundColor: green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: const Color(0xFF9E4141),
        ),
      );
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
            gradient: const LinearGradient(
              colors: [green, Color(0xFF314B51)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.16),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: surface,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
                  color: Colors.white.withValues(alpha: 0.14),
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
                        fontSize: 11,
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
        const SizedBox(height: 22),
        SizedBox(
          height: 49,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF633E45),
              foregroundColor: const Color(0xFFFFB9B9),
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
            style: TextStyle(color: mutedText, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: darkText,
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
      height: 43,
      width: 43,
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: cyan, size: 21),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cyan),
          const SizedBox(width: 9),
          SizedBox(
            width: 94,
            child: Text(
              title,
              style: const TextStyle(color: mutedText, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkText,
                fontSize: 11,
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
      color = const Color(0xFF28594F);
      foreground = const Color(0xFF9AE0C5);
    } else if (value == 'in_use' || value == 'active') {
      color = const Color(0xFF604A37);
      foreground = const Color(0xFFFFC47E);
    } else if (value == 'maintenance' || value == 'open') {
      color = const Color(0xFF633E45);
      foreground = const Color(0xFFFFB9B9);
    } else {
      color = softTeal;
      foreground = cyan;
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

  Widget _headerCard(
    String title,
    String subtitle,
    IconData icon,
    String footer,
  ) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [green, Color(0xFF314B51)],
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  footer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 59,
            width: 59,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 31),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: borderColor);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return const Center(child: CircularProgressIndicator(color: cyan));
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF8585), size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 49, color: mutedText),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText, fontSize: 12),
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
