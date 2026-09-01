import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderConfirmationScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final orderNumber = orderData['order_number'];
    final tokenNumber = orderData['token_number'];
    final isPaid = orderData['payment_status'] == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false, // Prevents back navigation to checkout
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Thank you for your order!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Order ID: $orderNumber',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (isPaid && tokenNumber != null) ...[
                Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Your Token Number',
                          style: TextStyle(fontSize: 18, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'T-${tokenNumber.toString().padLeft(3, '0')}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Please wait for your token to be called.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  color: Colors.amber.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade200, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: const [
                        Icon(Icons.payment, size: 48, color: Colors.amber),
                        SizedBox(height: 12),
                        Text(
                          'Please Pay at Counter',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your order is pending. Pay at the counter to receive your token number.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('BACK TO HOME', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
