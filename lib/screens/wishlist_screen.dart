import 'package:flutter/material.dart';
import '../services/mongo_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    final user = MongoService.currentUser;
    if (user == null) return [];

    final pipeline = [
      {
        '\$match': {'user_id': user['_id'].toString()}
      },
      {
        '\$addFields': {
          'food_item_objectId': { '\$toObjectId': '\$food_item_id' }
        }
      },
      {
        '\$lookup': {
          'from': 'food_items',
          'localField': 'food_item_objectId',
          'foreignField': '_id',
          'as': 'food_item_details'
        }
      }
    ];

    return await MongoService.collection('wishlists')
        .aggregateToStream(pipeline)
        .toList();
  }

  Future<void> _removeFromWishlist(String id) async {
    try {
      await MongoService.collection('wishlists').deleteOne({'_id': MongoService.parseObjectId(id)});
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWishlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load wishlist.'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Your wishlist is empty.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final details = item['food_item_details'] as List<dynamic>?;
              final foodDetails = (details != null && details.isNotEmpty) ? details.first : null;
              final stock = foodDetails != null ? (foodDetails['stock_quantity'] ?? 0) : 0;
              final inStock = stock > 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(item['food_item_image_url'] ?? ''),
                    radius: 25,
                  ),
                  title: Text(item['food_item_name'] ?? 'Unknown Item'),
                  subtitle: Text(
                    inStock ? 'In Stock ($stock)' : 'Out of Stock',
                    style: TextStyle(color: inStock ? Colors.green : Colors.red),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _removeFromWishlist(item['_id'].toString()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
