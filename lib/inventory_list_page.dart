import 'package:cafetrack/food_item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  String _userRole = 'user';
  // NEW: Controller and state for the search functionality
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
    // NEW: Listener to update the UI as the user types
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
    // NEW: Wrapped in a Column to hold the search bar and the list
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Food Items',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // Add a clear button to the search bar
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('food_items').snapshots(),
            builder: (ctx, foodItemsSnapshot) {
              if (foodItemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!foodItemsSnapshot.hasData ||
                  foodItemsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No food items found.'));
              }
              if (foodItemsSnapshot.hasError) {
                return const Center(child: Text('Something went wrong...'));
              }

              final allItems = foodItemsSnapshot.data!.docs;

              // NEW: Filtering logic
              final filteredItems = _searchQuery.isEmpty
                  ? allItems
                  : allItems.where((doc) {
                final itemData = doc.data() as Map<String, dynamic>;
                final itemName = (itemData['name'] as String?)?.toLowerCase() ?? '';
                return itemName.contains(_searchQuery);
              }).toList();

              if (filteredItems.isEmpty) {
                return const Center(child: Text('No matching items found.'));
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(10,0,10,10), // Adjust padding
                itemCount: filteredItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (ctx, index) {
                  final itemDoc = filteredItems[index];
                  final itemData = itemDoc.data() as Map<String, dynamic>;
                  final itemName = itemData['name'] ?? 'No Name';
                  final itemQuantity = itemData['quantity'] ?? 0;
                  final itemPrice =
                      (itemData['price'] as num?)?.toDouble() ?? 0.0;
                  final imageUrl = itemData['imageUrl'] ??
                      'https://placehold.co/400x400?text=No+Image';

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => FoodItemDetailsScreen(
                            foodDoc: itemDoc,
                            userRole: _userRole,
                          ),
                        ));
                      },
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
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child:
                                    Icon(Icons.error, color: Colors.red));
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
                                    itemName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Stock: $itemQuantity'),
                                  const Spacer(),
                                  Text(
                                    'BDT ${itemPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                      Theme.of(context).colorScheme.primary,
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
          ),
        ),
      ],
    );
  }
}

