import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ApiService api;
  const AdminDashboardScreen({super.key, required this.api});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF7C3AED);
  static const _bg = Color(0xFF0B0E14);
  static const _card = Color(0xFF131722);
  static const _border = Color(0xFF2A2E39);

  late TabController _tab;
  Timer? _timer;

  // Overview
  Map<String, dynamic> _dash = {};
  bool _dashLoading = true;

  // Users
  List<dynamic> _users = [];
  bool _usersLoading = true;
  bool _usersFetched = false;

  // Orders
  List<dynamic> _orders = [];
  bool _ordersLoading = true;
  bool _ordersFetched = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && !_usersFetched) _fetchUsers();
      if (_tab.index == 2 && !_ordersFetched) _fetchOrders();
    });
    _fetchDashboard();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchDashboard(silent: true);
      if (_tab.index == 1) _fetchUsers(silent: true);
      if (_tab.index == 2) _fetchOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard({bool silent = false}) async {
    if (!silent && mounted) setState(() => _dashLoading = true);
    try {
      final data = await widget.api.getAdminDashboard();
      if (mounted) setState(() { _dash = data; _dashLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _dashLoading = false);
    }
  }

  Future<void> _fetchUsers({bool silent = false}) async {
    if (!silent && mounted) setState(() => _usersLoading = true);
    try {
      final data = await widget.api.getAdminUsers();
      if (mounted) setState(() { _users = data; _usersLoading = false; _usersFetched = true; });
    } catch (_) {
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent && mounted) setState(() => _ordersLoading = true);
    try {
      final data = await widget.api.getAdminOrders();
      if (mounted) setState(() { _orders = data; _ordersLoading = false; _ordersFetched = true; });
    } catch (_) {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        leading: const SizedBox(),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: _purple, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          // Live req/sec pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: _purple, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${(_dash['reqPerSecond'] as num? ?? 0).toStringAsFixed(1)}/s',
                  style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF848E9C)),
            tooltip: 'Logout',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _purple,
          labelColor: _purple,
          unselectedLabelColor: const Color(0xFF848E9C),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    if (_dashLoading && _dash.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }

    final metrics = [
      _MetricDef('Req / Second', '${(_dash['reqPerSecond'] as num? ?? 0).toStringAsFixed(2)}/s', Icons.speed, Colors.blue),
      _MetricDef('Total Requests', '${_dash['totalRequests'] ?? 0}', Icons.call_received, Colors.teal),
      _MetricDef('Total Responses', '${_dash['totalResponses'] ?? 0}', Icons.call_made, const Color(0xFF00C087)),
      _MetricDef('Pending Requests', '${_dash['pendingRequests'] ?? 0}', Icons.hourglass_top, Colors.orange),
      _MetricDef('Transactions', '${_dash['totalTransactions'] ?? 0}', Icons.currency_rupee, Colors.green),
      _MetricDef('Pending Orders', '${_dash['pendingOrders'] ?? 0}', Icons.pending_actions, Colors.deepOrange),
      _MetricDef('Total Users', '${_dash['totalUsers'] ?? 0}', Icons.people, Colors.indigo),
      _MetricDef('Active Users', '${_dash['activeUsers'] ?? 0}', Icons.person_pin, const Color(0xFF00C087)),
      _MetricDef('Inactive Users', '${_dash['inactiveUsers'] ?? 0}', Icons.person_off_outlined, const Color(0xFFF6465D)),
    ];

    final activity = (_dash['recentActivity'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      color: _purple,
      backgroundColor: _card,
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) => _buildMetricCard(metrics[i]),
            ),
            const SizedBox(height: 20),

            // Recent activity
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('Recent Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('${activity.length} events', style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            if (activity.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.history_toggle_off, color: Colors.white.withValues(alpha: 0.2), size: 40),
                    const SizedBox(height: 8),
                    const Text('No activity yet', style: TextStyle(color: Color(0xFF5E6673))),
                  ]),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: activity.take(20).toList().asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value as Map<String, dynamic>;
                    final msg = item['message'] as String? ?? '';
                    final ts = item['timestamp'] as int? ?? 0;
                    final time = DateTime.fromMillisecondsSinceEpoch(ts);
                    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}:'
                        '${time.second.toString().padLeft(2, '0')}';

                    Color msgColor = const Color(0xFF848E9C);
                    IconData msgIcon = Icons.info_outline;
                    if (msg.startsWith('TRADE')) { msgColor = const Color(0xFF00C087); msgIcon = Icons.swap_horiz; }
                    else if (msg.startsWith('ADMIN')) { msgColor = _purple; msgIcon = Icons.admin_panel_settings; }
                    else if (msg.startsWith('ORDER')) { msgColor = Colors.blue; msgIcon = Icons.receipt_long; }

                    return Column(children: [
                      if (idx > 0) const Divider(color: Color(0xFF1E222D), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(msgIcon, color: msgColor, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(msg, style: TextStyle(color: msgColor, fontSize: 13))),
                            const SizedBox(width: 8),
                            Text(timeStr, style: const TextStyle(color: Color(0xFF5E6673), fontSize: 11, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(_MetricDef m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(m.icon, color: m.color, size: 22),
          const SizedBox(height: 6),
          Text(m.value, style: TextStyle(color: m.color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(m.label, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 9), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  // ── Users Tab ────────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_usersLoading && !_usersFetched) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.2), size: 48),
          const SizedBox(height: 12),
          const Text('No registered users yet', style: TextStyle(color: Color(0xFF5E6673))),
        ]),
      );
    }
    return RefreshIndicator(
      color: _purple,
      backgroundColor: _card,
      onRefresh: _fetchUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final u = _users[i] as Map<String, dynamic>;
          final name = (u['fullName'] as String? ?? '').trim();
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final active = u['active'] as bool? ?? false;
          final balance = (u['balance'] as num? ?? 0).toDouble();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _purple.withValues(alpha: 0.2),
                  child: Text(initial, style: const TextStyle(color: _purple, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('@${u['username'] ?? ''} • ${u['email'] ?? ''}',
                          style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('₹${balance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF00C087), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(u['id'] as String? ?? '', style: const TextStyle(color: Color(0xFF5E6673), fontSize: 10)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (active ? const Color(0xFF00C087) : const Color(0xFFF6465D)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? const Color(0xFF00C087) : const Color(0xFFF6465D), width: 0.8),
                      ),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(color: active ? const Color(0xFF00C087) : const Color(0xFFF6465D), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Orders Tab ───────────────────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    if (_ordersLoading && !_ordersFetched) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
          const SizedBox(height: 12),
          const Text('No orders placed yet', style: TextStyle(color: Color(0xFF5E6673))),
        ]),
      );
    }
    return RefreshIndicator(
      color: _purple,
      backgroundColor: _card,
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = _orders[i] as Map<String, dynamic>;
          final side = (o['side'] as String? ?? '').toUpperCase();
          final status = (o['status'] as String? ?? '').toUpperCase();
          final isBuy = side == 'BUY';

          Color sideColor = isBuy ? const Color(0xFF00C087) : const Color(0xFFF6465D);
          Color statusColor;
          switch (status) {
            case 'OPEN': statusColor = Colors.blue; break;
            case 'FILLED': statusColor = const Color(0xFF00C087); break;
            case 'CANCELLED': statusColor = const Color(0xFF848E9C); break;
            case 'PARTIAL': statusColor = Colors.orange; break;
            default: statusColor = const Color(0xFF848E9C);
          }

          final price = (o['price'] as num? ?? 0).toDouble();
          final qty = o['initialQuantity'] as int? ?? 0;
          final filled = o['filledQuantity'] as int? ?? 0;
          final ts = o['timestamp'] as int? ?? 0;
          final time = DateTime.fromMillisecondsSinceEpoch(ts);
          final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                // Side tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(side, style: TextStyle(color: sideColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(o['ticker'] as String? ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(o['type'] as String? ?? '', style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                      ]),
                      Text('₹${price.toStringAsFixed(2)} × $qty (filled: $filled)',
                          style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      Text('Trader: ${o['traderId'] ?? ''} • $timeStr',
                          style: const TextStyle(color: Color(0xFF5E6673), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 0.8),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricDef {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricDef(this.label, this.value, this.icon, this.color);
}
