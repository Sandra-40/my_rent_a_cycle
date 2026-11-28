import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const Color background = Color(0xFF263B40);
  static const Color surface = Color(0xFF314B51);
  static const Color primary = Color(0xFF23717B);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color textColor = Color(0xFFF1F8F8);
  static const Color mutedText = Color(0xFFB5C9CC);
  static const Color borderColor = Color(0xFF456168);
  static const Color softTeal = Color(0xFF3A555B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    final firstName = displayName.isEmpty
        ? 'there'
        : displayName.split(' ').first;

    return Scaffold(
      backgroundColor: background,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHomePage(firstName),
          const MyBookingsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: primary,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: mutedText),
            selectedIcon: Icon(Icons.home_rounded, color: cyan),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: mutedText),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: cyan),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: mutedText),
            selectedIcon: Icon(Icons.person_rounded, color: cyan),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(String firstName) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RENTACYCLE',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hello, $firstName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready for your next ride?',
                        style: TextStyle(color: mutedText, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() => selectedIndex = 2);
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: cyan,
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildHeroSection(),
            const SizedBox(height: 25),
            const Text(
              'Available Cycles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a ride for your campus journey.',
              style: TextStyle(color: mutedText, fontSize: 13),
            ),
            const SizedBox(height: 17),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('cycles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _messageCard(
                    'Unable to load cycles. Please try again later.',
                    Icons.error_outline_rounded,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: CircularProgressIndicator(color: cyan),
                    ),
                  );
                }

                final cycles =
                    snapshot.data?.docs.where((doc) {
                      final data = doc.data();
                      final status = (data['status'] ?? '')
                          .toString()
                          .toLowerCase();

                      final isMaintenance =
                          status == 'maintenance' ||
                          status == 'under maintenance';

                      return !isMaintenance;
                    }).toList() ??
                    [];

                if (cycles.isEmpty) {
                  return _messageCard(
                    'No cycles are available right now.',
                    Icons.pedal_bike_outlined,
                  );
                }

                return Column(
                  children: cycles.map((doc) {
                    final data = doc.data();

                    final name = (data['name'] ?? 'Campus Cycle').toString();
                    final type = (data['type'] ?? 'Standard').toString();
                    final location = (data['location'] ?? 'Campus').toString();
                    final status = (data['status'] ?? 'available').toString();
                    final rating = data['rating']?.toString() ?? '—';

                    return _buildCycleCard(
                      name: name,
                      type: type,
                      location: location,
                      status: status,
                      rating: rating,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23717B), Color(0xFF314B51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cyan.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cyan.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -20,
            child: Icon(
              Icons.pedal_bike_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'YOUR CAMPUS, YOUR RIDE',
                  style: TextStyle(
                    color: Color(0xFFE5F9F8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const SizedBox(
                width: 220,
                child: Text(
                  'Ride More.\nExplore More.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(
                width: 220,
                child: Text(
                  'Find your perfect cycle and make every campus journey easier.',
                  style: TextStyle(
                    color: Color(0xFFD9F0F2),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_outlined, color: cyan, size: 17),
                  SizedBox(width: 6),
                  Text(
                    'Simple • Smart • Sustainable',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard({
    required String name,
    required String type,
    required String location,
    required String status,
    required String rating,
  }) {
    final isAvailable = status.toLowerCase() == 'available';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 72,
                width: 76,
                decoration: BoxDecoration(
                  color: softTeal,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: cyan,
                  size: 43,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      type,
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: mutedText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4B42),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF2B544),
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Color(0xFFFFE6A7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF244F4D)
                      : const Color(0xFF514333),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      size: 13,
                      color: isAvailable
                          ? const Color(0xFF72D6C2)
                          : const Color(0xFFFFC875),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isAvailable
                            ? const Color(0xFF72D6C2)
                            : const Color(0xFFFFC875),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(cycleName: name),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: textColor,
                    disabledBackgroundColor: softTeal,
                    disabledForegroundColor: mutedText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: softTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 30, color: cyan),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedText, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
