import 'package:cafetrack_flutter/add_board_game_screen.dart';
import 'package:cafetrack_flutter/select_user_screen.dart';
import 'package:cafetrack_flutter/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoardGameDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> gameData;

  const BoardGameDetailsScreen({super.key, required this.gameData});

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
              MongoService.collection('board_games').deleteOne({'_id': gameData['_id']});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _assignGame(BuildContext context, Map<String, dynamic> userData) async {
    try {
      final gameId = gameData['_id'];
      
      // Fetch fresh game data
      final freshGame = await MongoService.collection('board_games').findOne({'_id': gameId});
      if (freshGame == null) throw Exception('Game not found.');

      if (freshGame['available_units'] > 0) {
        // Update game
        await MongoService.collection('board_games').updateOne(
          {'_id': gameId},
          {'\$set': {'available_units': freshGame['available_units'] - 1}}
        );
        
        // Insert assignment
        await MongoService.collection('assignments').insertOne({
          'board_game_id': gameId,
          'user_id': userData['_id'],
          'userName': userData['name'],
          'userStudentId': userData['studentId'],
          'userDepartment': userData['department'],
          'userIntake': userData['intake'],
          'assigned_at': DateTime.now().toIso8601String(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game assigned successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('No games available to assign.');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign game: ${error.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _returnGame(BuildContext context, Map<String, dynamic> assignmentData) async {
    try {
      final gameId = gameData['_id'];

      // Fetch fresh game data
      final freshGame = await MongoService.collection('board_games').findOne({'_id': gameId});
      if (freshGame != null) {
        await MongoService.collection('board_games').updateOne(
          {'_id': gameId},
          {'\$set': {'available_units': freshGame['available_units'] + 1}}
        );
      }
      
      await MongoService.collection('assignments').deleteOne({'_id': assignmentData['_id']});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game returned successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to return game: ${error.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: MongoService.collection('board_games').findOne({'_id': gameData['_id']}),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final freshGameData = snapshot.data!;
        final gameName = freshGameData['name'] ?? 'No Name';
        final totalUnits = freshGameData['total_units'] ?? 0;
        final availableUnits = freshGameData['available_units'] ?? 0;
        final imageUrl = freshGameData['image_url'] ?? 'https://placehold.co/600x400?text=No+Image';

        return Scaffold(
          appBar: AppBar(
            title: Text(gameName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddBoardGameScreen(boardGameData: freshGameData))),
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
                          final selectedUser = await Navigator.of(context).push<Map<String, dynamic>>(
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
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: MongoService.collection('assignments').find(mongo.where.eq('board_game_id', gameData['_id']).sortBy('assigned_at', descending: true)).toList(),
                        builder: (ctx, assignmentSnapshot) {
                          if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No games currently assigned.')));
                          }

                          final assignments = assignmentSnapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: assignments.length,
                            itemBuilder: (ctx, index) {
                              final assignmentData = assignments[index];
                              final userName = assignmentData['userName'] ?? 'Unknown User';
                              final userStudentId = assignmentData['userStudentId'] ?? 'No ID';
                              final userDepartment = assignmentData['userDepartment'] ?? 'N/A';
                              final userIntake = assignmentData['userIntake'] ?? '';
                              final assignedAtStr = assignmentData['assigned_at'];
                              final assignedAt = assignedAtStr != null ? DateTime.tryParse(assignedAtStr) : null;
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

