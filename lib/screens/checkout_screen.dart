import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/mongo_service.dart';
import 'bkash_payment_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _orderType = 'dine_in';
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    final cart = CartService();
    if (cart.items.isEmpty) return;

    if (_paymentMethod == 'bkash') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => BkashPaymentScreen(
            orderType: _orderType,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = MongoService.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final orderNumber = await MongoService.getNextOrderNumber();

      final itemsList = cart.items.values.map((item) {
        return {
          'food_item_id': item.foodItemId,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'image_url': item.imageUrl,
        };
      }).toList();

      final orderData = {
        'order_number': orderNumber,
        'user_id': user['_id'].toString(),
        'user_name': user['name'] ?? 'Unknown',
        'user_email': user['email'] ?? 'Unknown',
        'user_student_id': user['studentId'] ?? 'Unknown',
        'order_type': _orderType,
        'payment_method': _paymentMethod,
        'payment_status': 'unpaid',
        'order_status': 'pending',
        'token_number': null,
        'bkash_transaction_id': null,
        'items': itemsList,
        'subtotal': cart.totalAmount,
        'total': cart.totalAmount,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await MongoService.collection('orders').insertOne(orderData);
      
      cart.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => OrderConfirmationScreen(orderData: orderData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
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
  Widget build(BuildContext context) {
    final cart = CartService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return ListTile(
                        title: Text('${item.quantity}x ${item.name}'),
                        trailing: Text('BDT ${(item.price * item.quantity).toStringAsFixed(2)}'),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    trailing: Text('BDT ${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  Text('Order Type', style: Theme.of(context).textTheme.titleLarge),
                  RadioListTile<String>(
                    title: const Text('Dine-in'),
                    value: 'dine_in',
                    groupValue: _orderType,
                    onChanged: (value) {
                      setState(() {
                        _orderType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Takeaway'),
                    value: 'takeaway',
                    groupValue: _orderType,
                    onChanged: (value) {
                      setState(() {
                        _orderType = value!;
                      });
                    },
                  ),
                  if (_orderType == 'takeaway')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        border: Border.all(color: Colors.yellow.shade400),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notice: Takeaway orders must be picked up within 30 minutes, or they will be automatically cancelled.',
                              style: TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Payment Method', style: Theme.of(context).textTheme.titleLarge),
                  RadioListTile<String>(
                    title: const Text('Cash (Pay at counter)'),
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('bKash (Online)'),
                    value: 'bkash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('PLACE ORDER', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
