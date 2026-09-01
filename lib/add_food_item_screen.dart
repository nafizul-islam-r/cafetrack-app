import 'package:flutter/material.dart';
import 'package:cafetrack_flutter/services/mongo_service.dart';

class AddFoodItemScreen extends StatefulWidget {
  final Map<String, dynamic>? foodItem;

  const AddFoodItemScreen({super.key, this.foodItem});

  @override
  State<AddFoodItemScreen> createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _isEditing => widget.foodItem != null;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUrlController = TextEditingController(); // New controller

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.foodItem!;
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _quantityController.text = (data['stock_quantity'] ?? 0).toString();
      _imageUrlController.text = data['image_url'] ?? ''; // Pre-fill image URL
    }
  }

  Future<void> _saveItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_quantityController.text.trim());

    try {
      if (widget.foodItem == null) {
        await MongoService.collection('food_items').insertOne({
          'name': _nameController.text.trim(),
          'price': price,
          'stock_quantity': stock,
          'image_url': _imageUrlController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully!')));
      } else {
        final oldStock = widget.foodItem!['stock_quantity'] as int? ?? 0;
        
        await MongoService.collection('food_items').updateOne(
          {'_id': widget.foodItem!['_id']},
          {
            '\$set': {
              'name': _nameController.text.trim(),
              'price': price,
              'stock_quantity': stock,
              'image_url': _imageUrlController.text.trim(),
              'updated_at': DateTime.now().toIso8601String(),
            }
          },
        );

        if (oldStock == 0 && stock > 0) {
          await MongoService.collection('wishlists').deleteMany({
            'food_item_id': widget.foodItem!['_id'].toString(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully!')));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Food Item' : 'Add Food Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Please enter a valid name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price (BDT)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid, positive price.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity (Stock)'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid, non-negative number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image URL.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_isEditing ? 'Save Changes' : 'Save Item'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}