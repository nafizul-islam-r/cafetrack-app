import 'package:cafetrack/add_board_game_screen.dart';
import 'package:cafetrack/select_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoardGameDetailsScreen extends StatelessWidget {
  final DocumentSnapshot gameDoc;

  const BoardGameDetailsScreen({super.key, required this.gameDoc});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this game?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              gameDoc.reference.delete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _assignGame(BuildContext context, DocumentSnapshot userDoc) async {
    final gameRef = gameDoc.reference;
    final userData = userDoc.data() as Map<String, dynamic>;

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(gameRef);
      final data = freshSnapshot.data() as Map<String, dynamic>;

      if (data['availableUnits'] > 0) {
        transaction.update(gameRef, {'availableUnits': data['availableUnits'] - 1});
        final assignmentRef = gameRef.collection('assignments').doc();
        transaction.set(assignmentRef, {
          'userId': userDoc.id,
          'userName': userData['name'],
          'userStudentId': userData['studentId'],
          'userDepartment': userData['department'],
          'userIntake': userData['intake'],
          'assignedAt': Timestamp.now(),
        });
      } else {
        throw Exception('No games available to assign.');
      }
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game assigned successfully!'), backgroundColor: Colors.green),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign game: ${error.toString()}'), backgroundColor: Colors.red),
      );
    });
  }

  Future<void> _returnGame(BuildContext context, DocumentSnapshot assignmentDoc) async {
    final gameRef = gameDoc.reference;

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(gameRef);
      final data = freshSnapshot.data() as Map<String, dynamic>;
      transaction.update(gameRef, {'availableUnits': data['availableUnits'] + 1});
      transaction.delete(assignmentDoc.reference);
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game returned successfully!'), backgroundColor: Colors.green),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to return game: ${error.toString()}'), backgroundColor: Colors.red),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: gameDoc.reference.snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final gameData = snapshot.data!.data() as Map<String, dynamic>;
        final gameName = gameData['name'] ?? 'No Name';
        final totalUnits = gameData['totalUnits'] ?? 0;
        final availableUnits = gameData['availableUnits'] ?? 0;
        final imageUrl = gameData['imageUrl'] ?? 'https://placehold.co/600x400?text=No+Image';

        return Scaffold(
          appBar: AppBar(
            title: Text(gameName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddBoardGameScreen(boardGame: gameDoc))),
                tooltip: 'Edit Game',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context),
                tooltip: 'Delete Game',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  imageUrl,
                  height: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(height: 300, child: Center(child: Icon(Icons.error, color: Colors.red, size: 50)));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Availability', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('$availableUnits of $totalUnits units available', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: availableUnits > 0 ? () async {
                          final selectedUser = await Navigator.of(context).push<DocumentSnapshot>(
                            MaterialPageRoute(builder: (ctx) => const SelectUserScreen()),
                          );

                          if (selectedUser != null) {
                            _assignGame(context, selectedUser);
                          }
                        } : null,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign Game to User'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                      const SizedBox(height: 24),
                      Text('Current Assignments', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: gameDoc.reference.collection('assignments').orderBy('assignedAt', descending: true).snapshots(),
                        builder: (ctx, assignmentSnapshot) {
                          if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.docs.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No games currently assigned.')));
                          }

                          final assignments = assignmentSnapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: assignments.length,
                            itemBuilder: (ctx, index) {
                              final assignmentData = assignments[index].data() as Map<String, dynamic>;
                              final userName = assignmentData['userName'] ?? 'Unknown User';
                              final userStudentId = assignmentData['userStudentId'] ?? 'No ID';
                              final userDepartment = assignmentData['userDepartment'] ?? 'N/A';
                              final userIntake = assignmentData['userIntake'] ?? '';
                              final assignedAt = (assignmentData['assignedAt'] as Timestamp?)?.toDate();
                              final formattedDate = assignedAt != null ? DateFormat.yMMMd().add_jm().format(assignedAt) : 'No date';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(userName),
                                  // CORRECTED: The subtitle is now a proper Column widget.
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: $userStudentId'),
                                      Text('Dept: $userDepartment-$userIntake'),
                                      Text('On: $formattedDate'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: ElevatedButton(
                                    child: const Text('Return'),
                                    onPressed: () => _returnGame(context, assignments[index]),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

