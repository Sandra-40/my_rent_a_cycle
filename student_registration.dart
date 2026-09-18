import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRegistration extends StatefulWidget {
  const StudentRegistration({super.key});

  @override
  State<StudentRegistration> createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final _formKey = GlobalKey<FormState>();

  final admissionController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedDepartment;
  String? selectedBatch;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // BLUE THEME COLORS
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173B6C);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color textDark = Color(0xFF334155);
  static const Color textGrey = Color(0xFF7A8794);

  @override
  void dispose() {
    admissionController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDepartment == null || selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select department and batch')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create Firebase Authentication account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Registration failed');
      }

      // Save student information in Firestore
      await _firestore.collection('students').doc(user.uid).set({
        'admissionNumber': admissionController.text.trim(),
        'fullName': nameController.text.trim(),
        'department': selectedDepartment,
        'batch': selectedBatch,
        'email': emailController.text.trim(),
        'role': 'user',
        'suspended': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out after registration
      await _auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),

      prefixIcon: Icon(icon, color: primaryBlue),

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
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(Icons.arrow_back_rounded, color: darkBlue),
        ),

        title: const Text(
          'Student Registration',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const SizedBox(height: 10),

                // BICYCLE ICON
                Center(
                  child: Container(
                    width: 75,
                    height: 75,

                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.pedal_bike_rounded,
                      size: 42,
                      color: primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // TITLE
                const Text(
                  'Create Student Account',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 8),

                // SUBTITLE
                const Text(
                  'Register to start your cycling journey',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 14, color: textGrey),
                ),

                const SizedBox(height: 30),

                // ADMISSION NUMBER
                TextFormField(
                  controller: admissionController,

                  decoration: inputDecoration(
                    'Admission Number',
                    Icons.badge_outlined,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter admission number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // FULL NAME
                TextFormField(
                  controller: nameController,

                  decoration: inputDecoration(
                    'Full Name',
                    Icons.person_outline,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // DEPARTMENT
                DropdownButtonFormField<String>(
                  value: selectedDepartment,

                  decoration: inputDecoration(
                    'Department',
                    Icons.school_outlined,
                  ),

                  dropdownColor: Colors.white,

                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryBlue,
                  ),

                  items: const [
                    DropdownMenuItem(value: 'CSE', child: Text('CSE')),

                    DropdownMenuItem(value: 'ECE', child: Text('ECE')),
                  ],

                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value;
                    });
                  },

                  validator: (value) {
                    if (value == null) {
                      return 'Select department';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // BATCH
                DropdownButtonFormField<String>(
                  value: selectedBatch,

                  decoration: inputDecoration(
                    'Batch',
                    Icons.calendar_today_outlined,
                  ),

                  dropdownColor: Colors.white,

                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryBlue,
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: '2022-2026',
                      child: Text('2022-2026'),
                    ),
                  ],

                  onChanged: (value) {
                    setState(() {
                      selectedBatch = value;
                    });
                  },

                  validator: (value) {
                    if (value == null) {
                      return 'Select batch';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // EMAIL
                TextFormField(
                  controller: emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: inputDecoration('Email', Icons.email_outlined),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter email';
                    }

                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextFormField(
                  controller: passwordController,

                  obscureText: obscurePassword,

                  decoration:
                      inputDecoration(
                        'Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,

                            color: textGrey,
                          ),

                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: confirmPasswordController,

                  obscureText: obscureConfirmPassword,

                  decoration:
                      inputDecoration(
                        'Confirm Password',
                        Icons.lock_reset_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,

                            color: textGrey,
                          ),

                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }

                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // REGISTER BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerStudent,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: isLoading
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
                                'Create Account',

                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(width: 10),

                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 15),

                // LOGIN BUTTON
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

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
                ),

                const SizedBox(height: 15),

                // INFORMATION BOX
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
                      Icon(
                        Icons.info_outline_rounded,
                        color: primaryBlue,
                        size: 22,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Your student information will be securely stored in Firebase.',

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
