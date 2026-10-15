import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  final ApiService api;
  final String traderId;

  const OrdersScreen({
    super.key,
    required this.api,
    required this.traderId,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _activeFilter = 'ALL'; // ALL, OPEN, FILLED, CANCELLED

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await widget.api.getOrders(widget.traderId);
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Are you sure you want to cancel resting order $orderId?', style: const TextStyle(color: Color(0xFF848E9C))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep', style: TextStyle(color: Color(0xFF848E9C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6465D)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.api.cancelOrder(orderId);
      if (success) {
        _fetchOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order $orderId cancelled successfully.'),
              backgroundColor: const Color(0xFF00C087),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _orders.where((o) {
      if (_activeFilter == 'OPEN') return o.isOpen;
      if (_activeFilter == 'FILLED') return o.isFilled;
      if (_activeFilter == 'CANCELLED') return o.isCancelled || o.isRejected;
      return true;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF00C087),
      backgroundColor: const Color(0xFF131722),
      onRefresh: _fetchOrders,
      child: Column(
        children: [
          // Filter Tabs (ALL, OPEN, FILLED, CANCELLED)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF131722),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2E39)),
            ),
            child: Row(
              children: ['ALL', 'OPEN', 'FILLED', 'CANCELLED'].map((tab) {
                final isSelected = _activeFilter == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2A2E39) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF848E9C),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Orders count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER HISTORY (${filtered.length})',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF848E9C), size: 18),
                  onPressed: _fetchOrders,
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _loading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C087)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: Color(0xFF5E6673), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_activeFilter.toLowerCase()} orders found',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Placed orders will appear here in real-time.', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: order.sideColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.side == OrderSide.buy ? 'BUY' : 'SELL',
                      style: TextStyle(color: order.sideColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.ticker,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${order.type})',
                    style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11),
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: order.statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: order.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1E222D), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('₹${order.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Filled / Total', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${order.filledQuantity} / ${order.initialQuantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Time', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(order.formattedDate, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                ],
              ),
            ],
          ),

          // Cancel Action for open resting orders
          if (order.isOpen) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _cancelOrder(order.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF6465D),
                side: const BorderSide(color: Color(0xFFF6465D)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
