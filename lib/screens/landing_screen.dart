import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'student_registration.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primary = Color(0xFF176B50);
  static const Color darkGreen = Color(0xFF123D2E);
  static const Color background = Color(0xFFF7F9F7);
  static const Color mutedGreen = Color(0xFFE8F2EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF238461), Color(0xFF14543E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pedal_bike_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'RentaCycle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: darkGreen,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: mutedGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.eco_rounded, size: 15, color: primary),
                        SizedBox(width: 5),
                        Text(
                          'Go Green',
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F2EA),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bike_rounded,
                      size: 14,
                      color: primary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'CAMPUS CYCLE RENTAL',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Your Campus.\nYour Cycle.\nYour Journey.',
                style: TextStyle(
                  fontSize: 40,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Make every campus journey easier. Find a cycle, book your ride and explore a greener way to get around.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.8,
                  color: Color(0xFF718078),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 25, 22, 23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5F2E9), Color(0xFFD5E9DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 65,
                        color: primary.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      bottom: 28,
                      left: 0,
                      child: Icon(
                        Icons.circle_outlined,
                        size: 35,
                        color: primary.withValues(alpha: 0.08),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          height: 174,
                          width: 174,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.10),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pedal_bike_rounded,
                            size: 112,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Ride More. Worry Less.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A smarter way to explore your campus.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718078),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'MADE FOR YOUR CAMPUS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF829087),
                ),
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Quick QR Verification',
                subtitle: 'Start your ride with simple verification.',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.location_on_rounded,
                title: 'Track Your Ride',
                subtitle: 'Keep track of your cycle journey.',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.eco_rounded,
                title: 'Go Green',
                subtitle: 'Choose a cleaner way to move around.',
              ),
              const SizedBox(height: 38),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentRegistrationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(
                      color: Color(0xFFB9D3C2),
                      width: 1.4,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pedal_bike_rounded,
                      color: Color(0xFF9BAC9F),
                      size: 20,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'RentaCycle  •  Campus Mobility',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF98A49D),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFEDF1ED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26352D).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 47,
            width: 47,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2EA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF176B50), size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF183B2E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF829087),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_outward_rounded,
            color: Color(0xFF9BAC9F),
            size: 17,
          ),
        ],
      ),
    );
  }
}
