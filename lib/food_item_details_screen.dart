import 'package:cafetrack/add_food_item_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class FoodItemDetailsScreen extends StatefulWidget {
  final DocumentSnapshot foodDoc;
  final String userRole;

  const FoodItemDetailsScreen({
    super.key,
    required this.foodDoc,
    required this.userRole,
  });

  @override
  State<FoodItemDetailsScreen> createState() => _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends State<FoodItemDetailsScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

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
              widget.foodDoc.reference.delete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating to submit a review.')),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      await widget.foodDoc.reference.collection('reviews').add({
        'rating': _rating,
        'comment': _reviewController.text.trim(),
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userName': userName,
      });

      _reviewController.clear();
      setState(() { _rating = 0; });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!'), backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) { setState(() { _isSubmitting = false; }); }
    }
  }

  // New function for admins to delete a review
  Future<void> _deleteReview(DocumentReference reviewRef) async {
    try {
      await reviewRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.'), backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodData = widget.foodDoc.data() as Map<String, dynamic>;
    final itemName = foodData['name'] ?? 'No Name';
    final itemPrice = (foodData['price'] as num?)?.toDouble() ?? 0.0;
    final itemQuantity = foodData['quantity'] ?? 0;
    final imageUrl =
        foodData['imageUrl'] ?? 'https://placehold.co/600x400?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        actions: widget.userRole == 'admin'
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => AddFoodItemScreen(foodItem: widget.foodDoc),
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
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Leave a Review', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Center(
                    child: RatingBar.builder(
                      initialRating: 0, // Always start fresh
                      minRating: 1,
                      allowHalfRating: true,
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() { _rating = rating; });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reviewController,
                    decoration: const InputDecoration(labelText: 'Your Comment (optional)', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_isSubmitting)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _submitReview,
                      child: const Text('Submit Review'),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Reviews', style: Theme.of(context).textTheme.titleLarge),

                  // NEW: StreamBuilder to display the list of reviews
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.foodDoc.reference.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
                    builder: (ctx, reviewSnapshot) {
                      if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No reviews yet. Be the first!')));
                      }

                      final reviews = reviewSnapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (ctx, index) {
                          final reviewData = reviews[index].data() as Map<String, dynamic>;
                          final userName = reviewData['userName'] ?? 'Anonymous';
                          final rating = reviewData['rating'] ?? 0.0;
                          final comment = reviewData['comment'] ?? '';
                          final createdAt = (reviewData['createdAt'] as Timestamp?)?.toDate();
                          final formattedDate = createdAt != null ? DateFormat.yMMMd().format(createdAt) : '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RatingBarIndicator(
                                    rating: rating.toDouble(),
                                    itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                  ),
                                  if (comment.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(comment),
                                    ),
                                ],
                              ),
                              // Show a delete button for admins
                              trailing: widget.userRole == 'admin' ? IconButton(
                                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                onPressed: () => _deleteReview(reviews[index].reference),
                              ) : null,
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
  }
}