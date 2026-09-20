import 'package:flutter/material.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // SAME BLUE COLORS USED IN LOGIN & REGISTRATION
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white],
            ),
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),

            child: Column(
              children: [
                const SizedBox(height: 20),

                // =========================
                // LOGO
                // =========================
                ScaleTransition(
                  scale: _scaleAnimation,

                  child: Container(
                    width: 100,
                    height: 100,

                    decoration: BoxDecoration(
                      color: lightBlue,

                      borderRadius: BorderRadius.circular(30),

                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.25),

                          blurRadius: 25,

                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.directions_bike_rounded,

                      color: primaryBlue,

                      size: 58,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // =========================
                // APP NAME
                // =========================
                FadeTransition(
                  opacity: _fadeAnimation,

                  child: const Column(
                    children: [
                      Text(
                        'Rent a Cycle',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 32,

                          fontWeight: FontWeight.bold,

                          color: darkBlue,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'CAMPUS CYCLE RENTAL',

                        style: TextStyle(
                          fontSize: 12,

                          letterSpacing: 3,

                          fontWeight: FontWeight.w600,

                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // DESCRIPTION
                // =========================
                SlideTransition(
                  position: _slideAnimation,

                  child: FadeTransition(
                    opacity: _fadeAnimation,

                    child: const Text(
                      'Smart, simple and sustainable\n'
                      'campus transportation.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,

                        height: 1.5,

                        color: textGrey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // =========================
                // FEATURE CARDS
                // =========================
                SlideTransition(
                  position: _slideAnimation,

                  child: Column(
                    children: [
                      _buildFeatureCard(
                        icon: Icons.qr_code_scanner_rounded,

                        title: 'Scan QR',

                        description:
                            'Scan the QR code and unlock your cycle instantly.',
                      ),

                      const SizedBox(height: 14),

                      _buildFeatureCard(
                        icon: Icons.location_on_rounded,

                        title: 'Track Ride',

                        description:
                            'Track your ride and view your journey distance.',
                      ),

                      const SizedBox(height: 14),

                      _buildFeatureCard(
                        icon: Icons.eco_rounded,

                        title: 'Go Green',

                        description:
                            'Choose zero-emission transportation for your campus.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // =========================
                // GET STARTED BUTTON
                // =========================
                FadeTransition(
                  opacity: _fadeAnimation,

                  child: SizedBox(
                    width: double.infinity,

                    height: 58,

                    child: ElevatedButton(
                      onPressed: _goToLogin,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,

                        foregroundColor: Colors.white,

                        elevation: 4,

                        shadowColor: primaryBlue.withOpacity(0.25),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            'Get Started',

                            style: TextStyle(
                              fontSize: 17,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(width: 10),

                          Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // LOGIN LINK
                // =========================
                TextButton(
                  onPressed: _goToLogin,

                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',

                      style: TextStyle(color: textGrey, fontSize: 14),

                      children: [
                        TextSpan(
                          text: 'Login',

                          style: TextStyle(
                            color: primaryBlue,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // FOOTER
                // =========================
                const Text(
                  'Ride • Track • Go Green',

                  style: TextStyle(
                    fontSize: 12,

                    color: primaryBlue,

                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // FEATURE CARD
  // =========================

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE2E8F0)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),

            blurRadius: 15,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          // ICON BOX
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: lightBlue,

              borderRadius: BorderRadius.circular(15),

              border: Border.all(color: borderBlue),
            ),

            child: Icon(icon, color: primaryBlue, size: 28),
          ),

          const SizedBox(width: 15),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.bold,

                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,

                  style: const TextStyle(
                    fontSize: 13,

                    height: 1.4,

                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
