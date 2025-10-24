import 'package:cafetrack/home_screen.dart'; // Import HomeScreen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _intakeController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _selectedDepartment;

  final List<String> _departments = [
    'CSE', 'BBA', 'EEE', 'Textile', 'CE', 'English', 'Economics', 'LL.B'
  ];

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    // Also check if department is selected in signup mode
    if (!isValid || (!_isLogin && _selectedDepartment == null)) {
      // Show specific error if department isn't selected during signup
      if(!_isLogin && _selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a department.'), backgroundColor: Colors.red),
        );
      }
      return; // Stop if form is invalid
    }
    _formKey.currentState!.save();
    setState(() { _isLoading = true; });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (_isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else { // Signup mode
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': _selectedDepartment,
          'intake': _intakeController.text.trim(),
          'studentId': _studentIdController.text.trim(),
          'role': 'user', // Default role
        });
      }

      // Navigate after successful login/signup
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication failed.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Ensure loading indicator stops even if there's an error after navigation check
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _intakeController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 150, // Adjust height as needed
                ),
              ),

              // Form Card
              Card(
                elevation: 5, // Added elevation for better visual separation
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Login Fields ---
                        if (_isLogin) ...[
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)), // Added icon
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Please enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), // Added icon
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                        ],

                        // --- Signup Fields ---
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)), // Added icon
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)), // Added icon
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Please enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), // Added icon
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedDepartment,
                            decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.school)), // Added icon
                            hint: const Text('Select Department'),
                            items: _departments.map((String department) {
                              return DropdownMenuItem<String>(
                                value: department,
                                child: Text(department),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedDepartment = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) { // Always require department for signup
                                return 'Please select a department.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _intakeController,
                            decoration: const InputDecoration(labelText: 'Intake (e.g., 49)', prefixIcon: Icon(Icons.numbers)), // Added icon
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) { // Always require intake for signup
                                return 'Please enter an intake.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _studentIdController,
                            decoration: const InputDecoration(labelText: 'Student ID', prefixIcon: Icon(Icons.badge)), // Added icon
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) { // Always require student ID for signup
                                return 'Please enter a student ID.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        // --- Buttons ---
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) // Rounded button
                            ),
                            child: Text(_isLogin ? 'Login' : 'Signup'),
                          ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(_isLogin
                              ? 'Create an account'
                              : 'I already have an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}