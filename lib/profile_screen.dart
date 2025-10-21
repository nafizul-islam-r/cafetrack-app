import 'package:cafetrack/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // To ensure we show the latest data, we set loading to true
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(child: Text('User data not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _userData!['name']?[0] ?? 'U', // First letter of name
              style: const TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userData!['name'] ?? 'No Name',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            _userData!['email'] ?? 'No Email',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Divider(),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Student ID'),
                  subtitle: Text(_userData!['studentId'] ?? 'Not set'),
                ),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Department'),
                  subtitle: Text(_userData!['department'] ?? 'Not set'),
                ),
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('Intake'),
                  subtitle: Text(_userData!['intake'] ?? 'Not set'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // NEW: The "Edit Profile" button
          ElevatedButton.icon(
            onPressed: () async {
              // Navigate to the edit screen and wait for it to close
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => EditProfileScreen(userData: _userData!),
                ),
              );
              // After returning, refresh the user data to show any changes
              _fetchUserData();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}