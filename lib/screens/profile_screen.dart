import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: Text(
            'Please log in to view your profile',
            style: TextStyle(color: darkTeal),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: darkTeal,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: cyan));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile details',
                style: TextStyle(color: darkTeal),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile details not found',
                style: TextStyle(color: darkTeal),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = data['fullName'] ?? 'Student';
          final email = data['email'] ?? user.email ?? '';
          final admissionNo = data['admissionNo'] ?? 'Not available';
          final department = data['department'] ?? 'Not available';
          final batch = data['batch'] ?? 'Not available';
          final role = data['role'] ?? 'user';
          final isSuspended = data['suspended'] == true;

          final initials = name
              .toString()
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _buildProfileHeader(
                name.toString(),
                email.toString(),
                initials,
                isSuspended,
              ),

              const SizedBox(height: 27),

              Row(
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: darkTeal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.badge_outlined, color: cyan, size: 22),
                ],
              ),

              const SizedBox(height: 5),

              const Text(
                'Your registered student details',
                style: TextStyle(fontSize: 13, color: mutedText),
              ),

              const SizedBox(height: 17),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _detailTile(
                      Icons.badge_outlined,
                      'Admission Number',
                      admissionNo.toString(),
                    ),
                    _detailDivider(),
                    _detailTile(
                      Icons.school_outlined,
                      'Department',
                      department.toString(),
                    ),
                    _detailDivider(),
                    _detailTile(
                      Icons.calendar_month_outlined,
                      'Batch',
                      batch.toString(),
                    ),
                    _detailDivider(),
                    _detailTile(
                      Icons.person_outline_rounded,
                      'Account Type',
                      role.toString(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 27),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: softTeal,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: cyan,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Smart, Ride Green',
                            style: TextStyle(
                              color: darkTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Making campus journeys easier and greener.',
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

              const SizedBox(height: 28),

              SizedBox(
                height: 53,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String email,
    String initials,
    bool isSuspended,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 27),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23717B), Color(0xFF314B51), Color(0xFF12B2C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: softTeal,
              child: Text(
                initials.isEmpty ? 'S' : initials,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE0F5F5)),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: isSuspended
                      ? const Color(0xFFFF8B8B)
                      : const Color(0xFF9BF0D8),
                ),
                const SizedBox(width: 7),
                Text(
                  isSuspended ? 'Suspended Account' : 'Active Account',
                  style: const TextStyle(
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
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: softTeal,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: cyan, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: mutedText),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return const Divider(height: 1, color: borderColor);
  }
}
