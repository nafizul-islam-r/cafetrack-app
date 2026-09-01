import 'package:cafetrack_flutter/add_food_item_screen.dart';
import 'package:cafetrack_flutter/services/mongo_service.dart';
import 'package:cafetrack_flutter/services/cart_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class FoodItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final String userRole;

  const FoodItemDetailsScreen({
    super.key,
    required this.foodData,
    required this.userRole,
  });

  @override
  State<FoodItemDetailsScreen> createState() => _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends State<FoodItemDetailsScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  int _quantity = 1;
  bool _canReview = false;
  bool _isLoadingReviewEligibility = true;

  bool _inWishlist = false;
  mongo.ObjectId? _wishlistId;

  @override
  void initState() {
    super.initState();
    _checkReviewEligibility();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = MongoService.currentUser;
    if (user == null || user['role'] == 'admin') return;

    final existing = await MongoService.collection('wishlists').findOne({
      'user_id': user['_id'].toString(),
      'food_item_id': widget.foodData['_id'].toString(),
    });

    if (mounted) {
      setState(() {
        _inWishlist = existing != null;
        if (existing != null) {
          _wishlistId = existing['_id'];
        } else {
          _wishlistId = null;
        }
      });
    }
  }

  Future<void> _toggleWishlist(String foodItemId, String name, double price, String imageUrl) async {
    final user = MongoService.currentUser;
    if (user == null) return;
    
    try {
      if (_inWishlist && _wishlistId != null) {
        await MongoService.collection('wishlists').deleteOne({'_id': _wishlistId});
        if (mounted) {
          setState(() {
            _inWishlist = false;
            _wishlistId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
        }
      } else {
        final doc = {
          'user_id': user['_id'].toString(),
          'food_item_id': foodItemId,
          'food_item_name': name,
          'food_item_price': price,
          'food_item_image_url': imageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        final result = await MongoService.collection('wishlists').insertOne(doc);
        if (mounted) {
          setState(() {
            _inWishlist = true;
            _wishlistId = result.id as mongo.ObjectId?;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _checkReviewEligibility() async {
    final user = MongoService.currentUser;
    if (user == null || user['role'] == 'admin') {
      if (mounted) setState(() { _isLoadingReviewEligibility = false; });
      return;
    }

    try {
      final hasCompletedOrder = await MongoService.collection('orders').findOne({
        'user_id': user['_id'].toString(),
        'order_status': 'completed',
        'items.food_item_id': widget.foodData['_id'].toString(),
      });
      
      if (mounted) {
        setState(() {
          _canReview = hasCompletedOrder != null;
          _isLoadingReviewEligibility = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingReviewEligibility = false; });
    }
  }

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
              MongoService.collection('food_items').deleteOne({'_id': widget.foodData['_id']});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    final user = MongoService.currentUser;
    if (user == null || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating to submit a review.')),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final userName = user['name'] ?? 'Anonymous';

      await MongoService.collection('reviews').insertOne({
        'rating': _rating,
        'comment': _reviewController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user['_id'],
        'food_item_id': widget.foodData['_id'],
        'userName': userName, // Store directly for easy display
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

  Future<void> _deleteReview(mongo.ObjectId reviewId) async {
    try {
      await MongoService.collection('reviews').deleteOne({'_id': reviewId});
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
    final foodData = widget.foodData;
    final itemName = foodData['name'] ?? 'No Name';
    final itemPrice = (foodData['price'] as num?)?.toDouble() ?? 0.0;
    final itemQuantity = foodData['stock_quantity'] ?? 0;
    final imageUrl =
        foodData['image_url'] ?? 'https://placehold.co/600x400?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        actions: widget.userRole == 'admin'
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => AddFoodItemScreen(foodItem: widget.foodData),
              )).then((_) => setState(() {})); // Refresh when returning
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
                  
                  if (itemQuantity > 0) ...[
                    Row(
                      children: [
                        const Text('Quantity:', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _quantity < itemQuantity ? () => setState(() => _quantity++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Add to Cart'),
                        onPressed: () {
                          try {
                            CartService().addItem(
                              foodData['_id'].toString(),
                              itemName,
                              itemPrice,
                              imageUrl,
                              itemQuantity,
                              quantity: _quantity,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added $itemName to cart')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(_inWishlist ? Icons.favorite : Icons.favorite_border),
                      label: Text(_inWishlist ? 'Remove from Wishlist' : 'Add to Wishlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _inWishlist ? Colors.grey.shade400 : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _toggleWishlist(foodData['_id'].toString(), itemName, itemPrice, imageUrl);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_isLoadingReviewEligibility)
                    const Center(child: CircularProgressIndicator())
                  else if (_canReview) ...[
                    Text('Leave a Review', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Center(
                      child: RatingBar.builder(
                        initialRating: 0,
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
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can only review this item after ordering it and receiving your completed order.',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Reviews', style: Theme.of(context).textTheme.titleLarge),

                  // NEW: FutureBuilder to display the list of reviews
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: MongoService.collection('reviews').find(mongo.where.eq('food_item_id', widget.foodData['_id']).sortBy('created_at', descending: true)).toList(),
                    builder: (ctx, reviewSnapshot) {
                      if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!reviewSnapshot.hasData || reviewSnapshot.data!.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No reviews yet. Be the first!')));
                      }

                      final reviews = reviewSnapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (ctx, index) {
                          final reviewData = reviews[index];
                          final userName = reviewData['userName'] ?? 'Anonymous';
                          final rating = reviewData['rating'] ?? 0.0;
                          final comment = reviewData['comment'] ?? '';
                          final createdAtStr = reviewData['created_at'];
                          final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
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
                                onPressed: () {
                                  _deleteReview(reviews[index]['_id']);
                                  setState(() {});
                                },
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