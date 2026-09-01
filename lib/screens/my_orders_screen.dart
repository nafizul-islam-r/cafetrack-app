import 'package:flutter/material.dart';
import '../services/mongo_service.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  Future<List<Map<String, dynamic>>> _fetchMyOrders() async {
    final user = MongoService.currentUser;
    if (user == null) return [];
    
    return await MongoService.collection('orders')
        .find({
          'user_id': user['_id'].toString()
        })
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA); // Descending
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load orders.'));
          }
          
          final orders = snapshot.data ?? [];
          
          final pendingTakeaways = orders.where((o) => o['order_status'] == 'pending' && o['order_type'] == 'takeaway').toList();

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'You have no orders yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              if (pendingTakeaways.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: Colors.amber.shade700, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have ${pendingTakeaways.length} takeaway order(s) awaiting pickup!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...pendingTakeaways.map((pto) {
                        final createdAt = DateTime.tryParse(pto['created_at']) ?? DateTime.now();
                        final elapsed = DateTime.now().difference(createdAt).inMinutes;
                        final remaining = (30 - elapsed).clamp(0, 30);
                        return Padding(
                          padding: const EdgeInsets.only(left: 32, top: 4),
                          child: Text(
                            '${pto['order_number']} - Expires in $remaining minute(s)',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
              final order = orders[index];
              final orderStatus = order['order_status'] ?? 'pending';
              final createdAt = DateTime.tryParse(order['created_at']);
              final formattedDate = createdAt != null 
                  ? DateFormat('MMM d, yyyy h:mm a').format(createdAt) 
                  : '';

              Color statusColor;
              if (orderStatus == 'completed') statusColor = Colors.green;
              else if (orderStatus == 'pending') statusColor = Colors.blue;
              else if (orderStatus == 'cancelled') statusColor = Colors.red;
              else statusColor = Colors.grey;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Order ${order['order_number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Total: BDT ${order['total'].toStringAsFixed(2)}'),
                      Text(formattedDate, style: const TextStyle(fontSize: 12)),
                      if (order['token_number'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Token: T-${order['token_number'].toString().padLeft(3, '0')}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      orderStatus.toString().toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => OrderDetailScreen(
                          orderData: order,
                          isAdmin: false,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  },
),
    );
  }
}
