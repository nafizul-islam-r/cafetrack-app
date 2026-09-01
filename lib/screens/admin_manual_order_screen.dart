import 'package:flutter/material.dart';
import '../services/mongo_service.dart';

class AdminManualOrderScreen extends StatefulWidget {
  const AdminManualOrderScreen({super.key});

  @override
  State<AdminManualOrderScreen> createState() => _AdminManualOrderScreenState();
}

class _AdminManualOrderScreenState extends State<AdminManualOrderScreen> {
  String _orderType = 'takeaway';
  String _paymentMethod = 'cash';
  final TextEditingController _customerNameController = TextEditingController();

  List<Map<String, dynamic>> _availableFoods = [];
  Map<String, int> _cart = {}; // food_item_id -> quantity
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  Future<void> _fetchFoodItems() async {
    final foods = await MongoService.collection('food_items')
        .find({'stock_quantity': {'\$gt': 0}})
        .toList();
    setState(() {
      _availableFoods = foods;
      _isLoading = false;
    });
  }

  double get _total {
    double total = 0;
    _cart.forEach((id, qty) {
      final item = _availableFoods.firstWhere((f) => f['_id'].toString() == id);
      total += (item['price'] as num) * qty;
    });
    return total;
  }

  void _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    final name = _customerNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer name')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final orderNumber = await MongoService.getNextOrderNumber();
      final tokenNumber = await MongoService.getNextTokenNumber();
      final now = DateTime.now().toIso8601String();

      List<Map<String, dynamic>> orderItems = [];
      for (var entry in _cart.entries) {
        final food = _availableFoods.firstWhere((f) => f['_id'].toString() == entry.key);
        orderItems.add({
          'food_item_id': food['_id'].toString(),
          'name': food['name'],
          'price': food['price'],
          'quantity': entry.value,
          'image_url': food['image_url'],
        });
        
        // deduct stock
        await MongoService.collection('food_items').update(
          {'_id': food['_id']},
          {'\$inc': {'stock_quantity': -entry.value}},
        );
      }

      final orderDoc = {
        'order_number': orderNumber,
        'token_number': tokenNumber,
        'user_id': null, // Guest
        'user_name': name,
        'user_student_id': 'Guest',
        'order_type': _orderType,
        'payment_method': _paymentMethod,
        'payment_status': 'paid', // manual orders are paid at counter
        'order_status': 'pending',
        'subtotal': _total,
        'total': _total,
        'items': orderItems,
        'created_at': now,
        'updated_at': now,
      };

      await MongoService.collection('orders').insertOne(orderDoc);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order created!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Manual Order')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _orderType,
                  decoration: const InputDecoration(labelText: 'Order Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
                    DropdownMenuItem(value: 'dine_in', child: Text('Dine-in')),
                  ],
                  onChanged: (v) => setState(() => _orderType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 24),
                const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ..._availableFoods.map((food) {
                  final id = food['_id'].toString();
                  final qty = _cart[id] ?? 0;
                  return ListTile(
                    title: Text(food['name']),
                    subtitle: Text('BDT ${food['price']} | Stock: ${food['stock_quantity']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: qty > 0 ? () => setState(() => _cart[id] = qty - 1) : null,
                        ),
                        Text('$qty'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: qty < (food['stock_quantity'] as num).toInt() 
                            ? () => setState(() => _cart[id] = qty + 1) : null,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text('Total: BDT $_total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitOrder,
                  child: const Text('Place Order'),
                ),
              ],
            ),
          ),
    );
  }
}
