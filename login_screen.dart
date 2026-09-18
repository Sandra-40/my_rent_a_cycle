import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'student_registration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;

  // BLUE THEME COLORS
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // FIREBASE LOGIN
  // ---------------------------------------------------------

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 1. LOGIN WITH FIREBASE AUTHENTICATION
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Login failed.');
      }

      // -----------------------------------------------------
      // 2. CHECK ADMIN
      // -----------------------------------------------------

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin login successful'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // For now, admins also go to HomeScreen.
        // Later we can create a separate Admin Dashboard.

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );

        return;
      }

      // -----------------------------------------------------
      // 3. CHECK STUDENT
      // -----------------------------------------------------

      final studentDoc = await _firestore
          .collection('students')
          .doc(user.uid)
          .get();

      if (!studentDoc.exists) {
        await _auth.signOut();

        throw Exception('Student account information was not found.');
      }

      // Get student data
      final studentData = studentDoc.data();

      // -----------------------------------------------------
      // 4. CHECK SUSPENDED STATUS
      // -----------------------------------------------------

      final bool suspended = studentData?['suspended'] == true;

      if (suspended) {
        await _auth.signOut();

        throw Exception(
          'Your account has been suspended. Please contact the administrator.',
        );
      }

      // -----------------------------------------------------
      // 5. STUDENT LOGIN SUCCESS
      // -----------------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student login successful'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // -----------------------------------------------------
      // 6. NOW GO TO HOME
      // -----------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      switch (e.code) {
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not send password reset email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // CREATE ACCOUNT
  // ---------------------------------------------------------

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegistration()),
    );
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: darkBlue),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 20),

                // LOGIN ICON
                Center(
                  child: Container(
                    width: 75,
                    height: 75,

                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 38,
                      color: primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // TITLE
                const Center(
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // SUBTITLE
                const Center(
                  child: Text(
                    'Login to continue your cycling journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: textGrey),
                  ),
                ),

                const SizedBox(height: 35),

                // EMAIL LABEL
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 8),

                // EMAIL FIELD
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    hintText: 'Enter your email',

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: primaryBlue,
                    ),

                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // PASSWORD LABEL
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 8),

                // PASSWORD FIELD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,

                  decoration: InputDecoration(
                    hintText: 'Enter your password',

                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: primaryBlue,
                    ),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },

                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must contain at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: _forgotPassword,

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(width: 10),

                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // DIVIDER
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),

                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),

                const SizedBox(height: 25),

                // CREATE ACCOUNT
                Center(
                  child: TextButton(
                    onPressed: _createAccount,

                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",

                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),

                        children: [
                          TextSpan(
                            text: 'Create one',

                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // INFO BOX
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: lightBlue,

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(color: borderBlue),
                  ),

                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(Icons.info_outline_rounded, color: primaryBlue),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Admin account can be configured in Firebase.\n'
                          'Student accounts are stored in Firebase Authentication and Firestore.',

                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
