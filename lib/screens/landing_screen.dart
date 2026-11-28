import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'student_registration.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFF1F2B2D);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color surface = Color(0xFF314B51);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color textColor = Color(0xFFF1F8F8);
  static const Color mutedText = Color(0xFFB5C9CC);
  static const Color borderColor = Color(0xFF456168);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(
                      Icons.pedal_bike_rounded,
                      color: cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    'RentaCycle',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: softTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: cyan, size: 7),
                        SizedBox(width: 6),
                        Text(
                          'CAMPUS',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 19,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SMART CAMPUS MOBILITY',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Campus rides,\nmade simple.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 31,
                        height: 1.16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Book a cycle, scan to unlock, and move around campus with ease.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 145,
                        width: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.22),
                          border: Border.all(
                            color: cyan.withValues(alpha: 0.3),
                            width: 1.3,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 112,
                              width: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cyan.withValues(alpha: 0.13),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.pedal_bike_rounded,
                              color: cyan,
                              size: 84,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Center(
                      child: Text(
                        'Scan. Ride. Go.',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'BUILT FOR YOUR RIDE',
                style: TextStyle(
                  color: cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: borderColor),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Quick unlock',
                      subtitle: 'Scan and verify your ride.',
                    ),
                    SizedBox(height: 14),
                    _FeatureRow(
                      icon: Icons.location_on_outlined,
                      title: 'Ride tracking',
                      subtitle: 'Keep your journey organized.',
                    ),
                    SizedBox(height: 14),
                    _FeatureRow(
                      icon: Icons.eco_outlined,
                      title: 'Eco-friendly',
                      subtitle: 'A greener way to get around.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 51,
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
                    backgroundColor: cyan,
                    foregroundColor: darkTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: borderColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'RENTA CYCLE  •  CAMPUS MOBILITY',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  static const Color cyan = Color(0xFF12B2C1);
  static const Color textColor = Color(0xFFF1F8F8);
  static const Color mutedText = Color(0xFFB5C9CC);
  static const Color softTeal = Color(0xFF3A555B);

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
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: softTeal,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: cyan, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
