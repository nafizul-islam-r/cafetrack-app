import 'package:cafetrack/add_food_item_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodItemDetailsScreen extends StatelessWidget {
  final DocumentSnapshot foodDoc;
  final String userRole;

  const FoodItemDetailsScreen({
    super.key,
    required this.foodDoc,
    required this.userRole,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this item?'),
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
              foodDoc.reference.delete();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodData = foodDoc.data() as Map<String, dynamic>;
    final itemName = foodData['name'] ?? 'No Name';
    final itemPrice = (foodData['price'] as num?)?.toDouble() ?? 0.0;
    final itemQuantity = foodData['quantity'] ?? 0;
    final imageUrl =
        foodData['imageUrl'] ?? 'https://placehold.co/600x400?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        actions: userRole == 'admin'
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => AddFoodItemScreen(foodItem: foodDoc),
              ));
            },
            tooltip: 'Edit Item',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Item',
          ),
        ]
            : [],
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
                return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()));
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                    height: 300,
                    child: Center(child: Icon(Icons.error, color: Colors.red)));
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BDT ${itemPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available Stock: $itemQuantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Placeholder for the review submission and list
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Review system coming soon.')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
