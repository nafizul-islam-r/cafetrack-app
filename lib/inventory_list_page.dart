import 'package:cafetrack_flutter/food_item_details_screen.dart';
import 'package:flutter/material.dart';
import 'services/mongo_service.dart';
import 'services/cart_service.dart';

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
    final user = MongoService.currentUser;
    if (user == null) return;
    if (mounted) {
      setState(() {
        _userRole = user['role'] ?? 'user';
      });
    }
  }

  Future<void> _addToWishlist(String foodItemId, String name, double price, String imageUrl) async {
    final user = MongoService.currentUser;
    if (user == null) return;
    
    try {
      // Check if already in wishlist
      final existing = await MongoService.collection('wishlists').findOne({
        'user_id': user['_id'].toString(),
        'food_item_id': foodItemId,
      });
      
      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already in wishlist')));
        }
        return;
      }
      
      await MongoService.collection('wishlists').insertOne({
        'user_id': user['_id'].toString(),
        'food_item_id': foodItemId,
        'food_item_name': name,
        'food_item_price': price,
        'food_item_image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: MongoService.collection('food_items').find().toList(),
            builder: (ctx, foodItemsSnapshot) {
              if (foodItemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!foodItemsSnapshot.hasData ||
                  foodItemsSnapshot.data!.isEmpty) {
                return const Center(child: Text('No food items found.'));
              }
              if (foodItemsSnapshot.hasError) {
                return const Center(child: Text('Something went wrong...'));
              }

              final allItems = foodItemsSnapshot.data!;

              // NEW: Filtering logic
              final filteredItems = _searchQuery.isEmpty
                  ? allItems
                  : allItems.where((itemData) {
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
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (ctx, index) {
                  final itemData = filteredItems[index];
                  final itemName = itemData['name'] ?? 'No Name';
                  final itemQuantity = itemData['stock_quantity'] ?? 0;
                  final itemPrice =
                      (itemData['price'] as num?)?.toDouble() ?? 0.0;
                  final imageUrl = itemData['image_url'] ??
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
                            foodData: itemData,
                            userRole: _userRole,
                          ),
                        )).then((_) => setState(() {})); // Refresh when returning
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'BDT ${itemPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (itemQuantity > 0)
                                        IconButton(
                                          icon: const Icon(Icons.add_shopping_cart, size: 20),
                                          color: Theme.of(context).colorScheme.primary,
                                          onPressed: () {
                                            try {
                                              CartService().addItem(
                                                itemData['_id'].toString(),
                                                itemName,
                                                itemPrice,
                                                imageUrl,
                                                itemQuantity,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Added $itemName to cart'), duration: const Duration(seconds: 1)),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                              );
                                            }
                                          },
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.favorite_border, size: 20),
                                          color: Colors.red,
                                          onPressed: () {
                                            _addToWishlist(itemData['_id'].toString(), itemName, itemPrice, imageUrl);
                                          },
                                        )
                                    ],
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

