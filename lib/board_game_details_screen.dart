import 'package:cafetrack/add_board_game_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Package for formatting dates

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
          TextButton(child: const Text('No'), onPressed: () => Navigator.of(ctx).pop()),
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

  void _showAssignDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Game'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: userIdController,
            decoration: const InputDecoration(labelText: 'Student ID or Faculty Code'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an ID.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Assign'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _assignGame(context, userIdController.text.trim());
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _assignGame(BuildContext context, String assignedToId) async {
    final gameRef = gameDoc.reference;

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(gameRef);
      final data = freshSnapshot.data() as Map<String, dynamic>;

      if (data['availableUnits'] > 0) {
        transaction.update(gameRef, {'availableUnits': data['availableUnits'] - 1});
        final assignmentRef = gameRef.collection('assignments').doc();
        transaction.set(assignmentRef, {
          'assignedTo': assignedToId,
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

  // NEW: Logic to handle returning a game.
  Future<void> _returnGame(BuildContext context, DocumentSnapshot assignmentDoc) async {
    final gameRef = gameDoc.reference;

    FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Get the most up-to-date version of the game document.
      final freshSnapshot = await transaction.get(gameRef);
      final data = freshSnapshot.data() as Map<String, dynamic>;

      // 2. Perform the updates.
      // a) Increase the available units count.
      transaction.update(gameRef, {'availableUnits': data['availableUnits'] + 1});
      // b) Delete the assignment record.
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
                        onPressed: availableUnits > 0 ? () => _showAssignDialog(context) : null, // Disable button if no games are available
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign Game to User'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                      const SizedBox(height: 24),
                      Text('Current Assignments', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),

                      // NEW: StreamBuilder to display the list of assignments.
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
                            shrinkWrap: true, // Important for nested lists
                            physics: const NeverScrollableScrollPhysics(), // Disables scrolling for the inner list
                            itemCount: assignments.length,
                            itemBuilder: (ctx, index) {
                              final assignmentData = assignments[index].data() as Map<String, dynamic>;
                              final assignedTo = assignmentData['assignedTo'] ?? 'Unknown';
                              final assignedAt = (assignmentData['assignedAt'] as Timestamp?)?.toDate();
                              final formattedDate = assignedAt != null ? DateFormat.yMMMd().add_jm().format(assignedAt) : 'No date';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(assignedTo),
                                  subtitle: Text('Assigned on: $formattedDate'),
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
