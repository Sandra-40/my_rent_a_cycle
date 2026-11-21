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
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Standard',
    'Sport',
    'Electric',
    'Mountain',
    'Foldable',
  ];

  final Color green = const Color(0xFF1B8A5A);
  final Color darkGreen = const Color(0xFF126642);
  final Color background = const Color(0xFFF5F8F5);

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
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFE0F2E7),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
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
                          color: Color(0xFF7A8A7E),
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
                          color: Color(0xFF20352A),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready for your next ride?',
                        style: TextStyle(
                          color: Color(0xFF7C8980),
                          fontSize: 14,
                        ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5ECE6)),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: green,
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildHeroSection(),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Find Your Cycle',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF20352A),
                  ),
                ),
                Icon(Icons.pedal_bike_rounded, color: green, size: 23),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose a cycle for your campus journey.',
              style: TextStyle(color: Color(0xFF849087), fontSize: 13),
            ),

            const SizedBox(height: 17),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: green,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? green : const Color(0xFFE4EAE5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF58675D),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => selectedFilter = filter);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(35),
                      child: CircularProgressIndicator(color: green),
                    ),
                  );
                }

                final cycles =
                    snapshot.data?.docs.where((doc) {
                      final data = doc.data();
                      final status = (data['status'] ?? '')
                          .toString()
                          .toLowerCase();
                      final type = (data['type'] ?? '')
                          .toString()
                          .toLowerCase();

                      final isMaintenance =
                          status == 'maintenance' ||
                          status == 'under maintenance';

                      final matchesFilter =
                          selectedFilter == 'All' ||
                          type == selectedFilter.toLowerCase();

                      return !isMaintenance && matchesFilter;
                    }).toList() ??
                    [];

                if (cycles.isEmpty) {
                  return _messageCard(
                    'No cycles available in this category right now.',
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
        gradient: LinearGradient(
          colors: [green, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.20),
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
              color: Colors.white.withValues(alpha: 0.12),
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
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'YOUR CAMPUS, YOUR RIDE',
                  style: TextStyle(
                    color: Colors.white,
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
                    color: Colors.white,
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
                    color: Color(0xFFD9F0E2),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.eco_outlined, color: Colors.white, size: 17),
                  SizedBox(width: 6),
                  Text(
                    'Simple • Smart • Sustainable',
                    style: TextStyle(
                      color: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDE8)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 72,
                width: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.pedal_bike_rounded, color: green, size: 43),
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
                        color: Color(0xFF26372C),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      type,
                      style: TextStyle(
                        color: green,
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
                          color: Color(0xFF89958C),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF89958C),
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
                  color: const Color(0xFFFFF7E5),
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
                        color: Color(0xFF7A632D),
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
          const Divider(height: 1, color: Color(0xFFEDF0ED)),
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
                      ? const Color(0xFFE6F5EB)
                      : const Color(0xFFFFF1DF),
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
                      color: isAvailable ? green : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isAvailable ? green : Colors.orange.shade800,
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
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE9EDEA),
                    disabledForegroundColor: Colors.grey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDE8)),
      ),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 30, color: green),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7D8980),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
