import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/profile_modal.dart';
import 'explore_stocks_screen.dart';
import 'holdings_screen.dart';
import 'positions_screen.dart';
import 'orders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AuthService auth;
  const MainNavigationScreen({super.key, required this.auth});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Default: Explore Stocks (index 0)

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;
    final traderId = user?.id ?? 'T001';

    final List<Widget> screens = [
      ExploreStocksScreen(api: widget.auth.api, traderId: traderId),
      HoldingsScreen(api: widget.auth.api, traderId: traderId),
      PositionsScreen(api: widget.auth.api, traderId: traderId),
      OrdersScreen(api: widget.auth.api, traderId: traderId),
    ];

    final List<String> titles = [
      'Explore Stocks',
      'Holdings',
      'Open Positions',
      'Orders',
    ];

    final userInitial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName[0].toUpperCase()
        : (user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'T');

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C087).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.candlestick_chart, color: Color(0xFF00C087), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              titles[_currentIndex],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Live Cash Balance Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2E39)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, color: Color(0xFF00C087), size: 14),
                const SizedBox(width: 5),
                Text(
                  '₹${(user?.balance ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF00C087), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Profile Icon at top right
          GestureDetector(
            onTap: () => showProfileModal(context, widget.auth),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C087), Color(0xFF007A54)],
                ),
                border: Border.all(color: const Color(0xFF2A2E39), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                userInitial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),

      // Screen Body
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // Bottom Navigation Bar with 4 Icons
      // 1. Explore Stocks (default)
      // 2. Holdings
      // 3. Open Positions
      // 4. Orders
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131722),
          border: Border(top: BorderSide(color: Color(0xFF2A2E39), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00C087).withValues(alpha: 0.18),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.travel_explore_outlined, color: Color(0xFF848E9C)),
              selectedIcon: Icon(Icons.travel_explore, color: Color(0xFF00C087)),
              label: 'Explore Stocks',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline, color: Color(0xFF848E9C)),
              selectedIcon: Icon(Icons.pie_chart, color: Color(0xFF00C087)),
              label: 'Holdings',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined, color: Color(0xFF848E9C)),
              selectedIcon: Icon(Icons.trending_up, color: Color(0xFF00C087)),
              label: 'Open Positions',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF848E9C)),
              selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF00C087)),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
