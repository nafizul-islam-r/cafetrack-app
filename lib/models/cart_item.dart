class CartItem {
  final String foodItemId;
  final String name;
  final double price;
  int quantity;
  final String imageUrl;
  final int maxStock;

  CartItem({
    required this.foodItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.maxStock,
  });

  Map<String, dynamic> toMap() {
    return {
      'food_item_id': foodItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }
}
