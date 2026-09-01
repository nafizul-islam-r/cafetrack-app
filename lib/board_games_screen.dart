import 'package:cafetrack_flutter/add_board_game_screen.dart';
import 'package:cafetrack_flutter/board_game_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cafetrack_flutter/services/mongo_service.dart';

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
    final user = MongoService.currentUser;
    if (user == null) return;
    if (mounted) {
      setState(() {
        _userRole = user['role'] ?? 'user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoService.collection('board_games').find().toList(),
      builder: (ctx, gamesSnapshot) {
        if (gamesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!gamesSnapshot.hasData || gamesSnapshot.data!.isEmpty) {
          return const Center(child: Text('No board games found.'));
        }
        if (gamesSnapshot.hasError) {
          return const Center(child: Text('Something went wrong...'));
        }

        final loadedGames = gamesSnapshot.data!;

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
            final gameData = loadedGames[index];
            final gameName = gameData['name'] ?? 'No Name';
            final totalUnits = gameData['total_units'] ?? 0;
            final availableUnits = gameData['available_units'] ?? 0;
            final imageUrl =
                gameData['image_url'] ?? 'https://placehold.co/400x400?text=No+Image';

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
                    builder: (ctx) => BoardGameDetailsScreen(gameData: gameData),
                  )).then((_) => setState(() {}));
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