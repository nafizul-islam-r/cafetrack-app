import 'package:cafetrack/add_board_game_screen.dart';
import 'package:cafetrack/board_game_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardGamesScreen extends StatefulWidget {
  const BoardGamesScreen({super.key});

  @override
  State<BoardGamesScreen> createState() => _BoardGamesScreenState();
}

class _BoardGamesScreenState extends State<BoardGamesScreen> {
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && userDoc.exists) {
      setState(() {
        _userRole = userDoc.data()?['role'] ?? 'user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('board_games').snapshots(),
      builder: (ctx, gamesSnapshot) {
        if (gamesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!gamesSnapshot.hasData || gamesSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No board games found.'));
        }
        if (gamesSnapshot.hasError) {
          return const Center(child: Text('Something went wrong...'));
        }

        final loadedGames = gamesSnapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: loadedGames.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (ctx, index) {
            final gameDoc = loadedGames[index];
            final gameData = gameDoc.data() as Map<String, dynamic>;
            final gameName = gameData['name'] ?? 'No Name';
            final totalUnits = gameData['totalUnits'] ?? 0;
            final availableUnits = gameData['availableUnits'] ?? 0;
            final imageUrl =
                gameData['imageUrl'] ?? 'https://placehold.co/400x400?text=No+Image';

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: InkWell(
                onTap: _userRole == 'admin'
                    ? () {
                  // Navigate to the NEW details screen
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => BoardGameDetailsScreen(gameDoc: gameDoc),
                  ));
                }
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.error, color: Colors.red));
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              'Available: $availableUnits / $totalUnits',
                              style: TextStyle(
                                fontSize: 14,
                                color: availableUnits > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}