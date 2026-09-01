import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mongo_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool isAdmin;

  const OrderDetailScreen({
    super.key,
    required this.orderData,
    required this.isAdmin,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _order;
  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isTakeawayPending = false;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.orderData);
    _checkTakeawayTimer();
  }

  void _checkTakeawayTimer() {
    if (_order['order_type'] == 'takeaway' && _order['order_status'] == 'pending') {
      final createdAtStr = _order['created_at'];
      if (createdAtStr != null) {
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt != null) {
          final expiryTime = createdAt.add(const Duration(minutes: 30));
          final now = DateTime.now();
          if (expiryTime.isAfter(now)) {
            _isTakeawayPending = true;
            _secondsRemaining = expiryTime.difference(now).inSeconds;
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted) {
                setState(() {
                  if (_secondsRemaining > 0) {
                    _secondsRemaining--;
                  } else {
                    _timer?.cancel();
                  }
                });
              }
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _markPaid() async {
    setState(() => _isLoading = true);
    try {
      final tokenNumber = await MongoService.getNextTokenNumber();
      await MongoService.collection('orders').updateOne(
        {'_id': _order['_id']},
        {'\$set': {
          'payment_status': 'paid',
          'token_number': tokenNumber
        }}
      );

      // Decrease stock
      final items = _order['items'] as List<dynamic>;
      for (final item in items) {
        await MongoService.collection('food_items').updateOne(
          {'_id': MongoService.parseObjectId(item['food_item_id'].toString())},
          {'\$inc': {'stock_quantity': -(item['quantity'] as int)}},
        );
      }

      setState(() {
        _order['payment_status'] = 'paid';
        _order['token_number'] = tokenNumber;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as paid.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _isLoading = true);
    try {
      await MongoService.collection('orders').updateOne(
        {'_id': _order['_id']},
        {'\$set': {'order_status': 'completed'}}
      );
      setState(() {
        _order['order_status'] = 'completed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as completed.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (_order['payment_status'] == 'paid') {
        // Restore stock
        final items = _order['items'] as List<dynamic>;
        for (final item in items) {
          await MongoService.collection('food_items').updateOne(
            {'_id': MongoService.parseObjectId(item['food_item_id'].toString())},
            {'\$inc': {'stock_quantity': (item['quantity'] as int)}},
          );
        }
      }

      await MongoService.collection('orders').updateOne(
        {'_id': _order['_id']},
        {'\$set': {'order_status': 'cancelled'}}
      );
      setState(() {
        _order['order_status'] = 'cancelled';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _order['items'] as List<dynamic>;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${_order['order_number']}'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isTakeawayPending && _order['order_status'] == 'pending') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow.shade400),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Takeaway Time Limit',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _secondsRemaining > 0
                            ? 'Please collect your order in ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')} or it will be automatically cancelled.'
                            : 'This order is expired and will be cancelled shortly.',
                          style: const TextStyle(color: Colors.deepOrange),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                ],
                // Status Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order Status:'),
                            Chip(label: Text(_order['order_status'].toString().toUpperCase())),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment:'),
                            Chip(label: Text('${_order['payment_status']} (${_order['payment_method']})'.toUpperCase())),
                          ],
                        ),
                        if (_order['token_number'] != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Token Number:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                Text('T-${_order['token_number'].toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Customer Section (Admin only)
                if (widget.isAdmin)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Name: ${_order['user_name']}'),
                          Text('Student ID: ${_order['user_student_id']}'),
                          Text('Email: ${_order['user_email']}'),
                        ],
                      ),
                    ),
                  ),
                
                if (widget.isAdmin) const SizedBox(height: 16),

                // Items Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items Ordered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            return ListTile(
                              leading: CircleAvatar(backgroundImage: NetworkImage(item['image_url'] ?? '')),
                              title: Text('${item['quantity']}x ${item['name']}'),
                              trailing: Text('BDT ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('BDT ${_order['total'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // Admin Actions Section
                if (widget.isAdmin && _order['order_status'] != 'completed' && _order['order_status'] != 'cancelled') ...[
                  const SizedBox(height: 24),
                  const Text('Admin Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_order['payment_status'] == 'unpaid')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _markPaid,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Mark as Paid (Generate Token)', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  if (_order['payment_status'] == 'paid')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _markCompleted,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('Mark as Completed', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cancelOrder,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]
              ],
            ),
          ),
    );
  }
}
