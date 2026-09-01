import 'package:flutter/material.dart';
import '../services/mongo_service.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';
import 'admin_manual_order_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filter = 'all'; // all, pending, completed, cancelled
  String _searchOrderQuery = '';
  String _searchTokenQuery = '';
  final TextEditingController _searchOrderController = TextEditingController();
  final TextEditingController _searchTokenController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final query = <String, dynamic>{};
    if (_filter != 'all') {
      query['order_status'] = _filter;
    }
    
    final orders = await MongoService.collection('orders')
        .find(query)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA); // Descending
      });

    return orders.where((o) {
      bool matchesOrder = true;
      bool matchesToken = true;

      if (_searchOrderQuery.isNotEmpty) {
        final q = _searchOrderQuery.toLowerCase();
        final orderNum = (o['order_number'] ?? '').toString().toLowerCase();
        matchesOrder = orderNum.contains(q);
      }

      if (_searchTokenQuery.isNotEmpty) {
        final q = _searchTokenQuery.toLowerCase();
        final token = o['token_number']?.toString() ?? '';
        final tStr = token.isNotEmpty ? 't-${token.padLeft(3, '0')}' : '';
        matchesToken = token == q || tStr.contains(q);
      }

      return matchesOrder && matchesToken;
    }).toList();
  }

  @override
  void dispose() {
    _searchOrderController.dispose();
    _searchTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchOrderController,
                          decoration: InputDecoration(
                            hintText: 'Search Order #',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          onChanged: (val) => setState(() => _searchOrderQuery = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchTokenController,
                          decoration: InputDecoration(
                            hintText: 'Search Token #',
                            prefixIcon: const Icon(Icons.confirmation_number),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          onChanged: (val) => setState(() => _searchTokenQuery = val),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', value: 'all', groupValue: _filter, onChanged: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Pending', value: 'pending', groupValue: _filter, onChanged: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Completed', value: 'completed', groupValue: _filter, onChanged: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Cancelled', value: 'cancelled', groupValue: _filter, onChanged: (v) => setState(() => _filter = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(),
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
                'No orders found.',
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
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order['order_number'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (order['token_number'] != null)
                        Text(
                          'T-${order['token_number'].toString().padLeft(3, '0')}',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        )
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${order['user_name']} (${order['user_student_id']})'),
                      Text('Total: BDT ${order['total'].toStringAsFixed(2)}'),
                      Text(formattedDate, style: const TextStyle(fontSize: 12)),
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
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => OrderDetailScreen(
                          orderData: order,
                          isAdmin: true,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminManualOrderScreen()),
          ).then((_) => setState(() {}));
        },
        label: const Text('Manual Order'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onChanged(value);
      },
    );
  }
}
