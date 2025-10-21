import 'package:cafetrack/inventory_list_page.dart';
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

  // NEW: State variable for the selected department
  String? _selectedDepartment;

  // NEW: List of departments for the dropdown
  final List<String> _departments = [
    'CSE', 'BBA', 'EEE', 'Textile', 'CE', 'English', 'Economics', 'LL.B'
  ];

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (_isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': _selectedDepartment, // Save the selected department
          'intake': _intakeController.text.trim(),
          'studentId': _studentIdController.text.trim(),
          'role': 'user',
        });
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const InventoryListPage()),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Full Name'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name.';
                              }
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address'),
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
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        if (!_isLogin) const SizedBox(height: 12),
                        // UPDATED: Changed from TextFormField to DropdownButtonFormField
                        if (!_isLogin)
                          DropdownButtonFormField<String>(
                            value: _selectedDepartment,
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
                              if (value == null) {
                                return 'Please select a department.';
                              }
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        if (!_isLogin)
                          TextFormField(
                            controller: _intakeController,
                            decoration: const InputDecoration(labelText: 'Intake (e.g., 49)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an intake.';
                              }
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        if (!_isLogin)
                          TextFormField(
                            controller: _studentIdController,
                            decoration: const InputDecoration(labelText: 'Student ID'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a student ID.';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _submit,
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