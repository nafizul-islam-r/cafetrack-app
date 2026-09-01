import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/mongo_service.dart';
import 'order_confirmation_screen.dart';

class BkashPaymentScreen extends StatefulWidget {
  final String orderType;

  const BkashPaymentScreen({
    super.key,
    required this.orderType,
  });

  @override
  State<BkashPaymentScreen> createState() => _BkashPaymentScreenState();
}

class _BkashPaymentScreenState extends State<BkashPaymentScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cart = CartService();
      final user = MongoService.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final orderNumber = await MongoService.getNextOrderNumber();
      final tokenNumber = await MongoService.getNextTokenNumber();

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
        'order_type': widget.orderType,
        'payment_method': 'bkash',
        'payment_status': 'paid',
        'order_status': 'pending',
        'token_number': tokenNumber,
        'bkash_transaction_id': 'SIM-TXN-${DateTime.now().millisecondsSinceEpoch}',
        'items': itemsList,
        'subtotal': cart.totalAmount,
        'total': cart.totalAmount,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await MongoService.collection('orders').insertOne(orderData);

      // Decrease stock for paid items
      for (final item in itemsList) {
        await MongoService.collection('food_items').updateOne(
          {'_id': MongoService.parseObjectId(item['food_item_id'].toString())},
          {'\$inc': {'stock_quantity': -(item['quantity'] as int)}},
        );
      }

      cart.clear();

      // Simulate a small delay for payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (ctx) => OrderConfirmationScreen(orderData: orderData),
          ),
          (route) => route.isFirst,
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = CartService().totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFE2136E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2136E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text('Processing Payment...', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://logos-download.com/wp-content/uploads/2022/01/BKash_Logo_icon-700x662.png',
                              height: 60,
                            ),
                            const SizedBox(height: 20),
                            const Text('Merchant: CafeTrack Campus', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            Text('Amount: BDT ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE2136E))),
                            const SizedBox(height: 30),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'bKash Account Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter account number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _pinController,
                              decoration: const InputDecoration(
                                labelText: 'bKash PIN',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter PIN';
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE2136E),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _processPayment,
                                child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
