import 'package:flutter/material.dart';
import 'booking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RentaCycle',
          style: TextStyle(
            color: darkBlue,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Profile will be connected later.
            },
            icon: const Icon(Icons.person_outline_rounded, color: darkBlue),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Ready for your next ride?',
                style: TextStyle(color: textGrey, fontSize: 15),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // MAIN BOOKING CARD
              // --------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.pedal_bike_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.lightGreen,
                                size: 9,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Available',
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

                    const SizedBox(height: 20),

                    const Text(
                      'Rent a Cycle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Choose an available cycle and start your campus ride.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 19),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookingScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Book a Cycle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // QUICK ACTIONS
              // --------------------------------------------------
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'My Bookings',
                      onTap: () {
                        _showComingSoon(context, 'My Bookings');
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR',
                      onTap: () {
                        _showComingSoon(context, 'QR Scanner');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.build_outlined,
                      title: 'Maintenance',
                      onTap: () {
                        _showComingSoon(context, 'Maintenance');
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      onTap: () {
                        _showComingSoon(context, 'Profile');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // CURRENT RIDE
              // --------------------------------------------------
              const Text(
                'Current Ride',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderBlue),
                ),
                child: Row(
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
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No active ride',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your current booking will appear here.',
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // CAMPUS CYCLE INFO
              // --------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(17),
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

                    SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Before you ride',
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Check the cycle condition, scan the QR code and return the cycle within your booked time.',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 12,
                              height: 1.5,
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
        ),
      ),

      // --------------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        elevation: 10,

        onTap: (index) {
          if (index == 0) {
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookingScreen()),
            );
          } else {
            _showComingSoon(context, index == 2 ? 'Maintenance' : 'Profile');
          }
        },

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
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build_rounded),
            label: 'Maintenance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTION CARD
  // ------------------------------------------------------------

  static Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 105,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderBlue),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryBlue, size: 23),
            ),

            const SizedBox(height: 9),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
