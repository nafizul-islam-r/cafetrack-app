import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectUserScreen extends StatefulWidget {
  const SelectUserScreen({super.key});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a User'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name or Student ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (ctx, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final allUsers = userSnapshot.data!.docs;
                final filteredUsers = _searchQuery.isEmpty
                    ? allUsers
                    : allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] as String?)?.toLowerCase() ?? '';
                  final studentId = (data['studentId'] as String?)?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) || studentId.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, index) {
                    final userDoc = filteredUsers[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final name = userData['name'] ?? 'No Name';
                    final studentId = userData['studentId'] ?? 'No ID';
                    final department = userData['department'] ?? 'No Dept';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('ID: $studentId | Dept: $department'),
                      onTap: () {
                        Navigator.of(context).pop(userDoc);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}