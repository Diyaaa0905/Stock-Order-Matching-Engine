import 'package:flutter/material.dart';
import '../models/position_model.dart';
import '../services/api_service.dart';
import 'stock_detail_screen.dart';

class HoldingsScreen extends StatefulWidget {
  final ApiService api;
  final String traderId;

  const HoldingsScreen({
    super.key,
    required this.api,
    required this.traderId,
  });

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  List<PositionModel> _holdings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHoldings();
  }

  Future<void> _fetchHoldings() async {
    setState(() => _loading = true);
    try {
      final holdings = await widget.api.getPortfolio(widget.traderId);
      if (mounted) {
        setState(() {
          _holdings = holdings;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalInvested = 0;
    double totalCurrent = 0;
    for (final p in _holdings) {
      totalInvested += p.totalInvested;
      totalCurrent += p.currentValue;
    }
    final totalPnL = totalCurrent - totalInvested;
    final totalPnLPercent = totalInvested > 0 ? (totalPnL / totalInvested) * 100 : 0.0;
    final isProfitable = totalPnL >= 0;
    final pnlColor = isProfitable ? const Color(0xFF00C087) : const Color(0xFFF6465D);

    return RefreshIndicator(
      color: const Color(0xFF00C087),
      backgroundColor: const Color(0xFF131722),
      onRefresh: _fetchHoldings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portfolio Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E222D), Color(0xFF131722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Portfolio Value', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalCurrent.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF2A2E39)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Invested', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('₹${totalInvested.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total P&L', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${isProfitable ? '+' : ''}₹${totalPnL.toStringAsFixed(2)} (${isProfitable ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%)',
                            style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Holdings List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOUR HOLDINGS (${_holdings.length})',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF848E9C), size: 18),
                  onPressed: _fetchHoldings,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading && _holdings.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF00C087))))
            else if (_holdings.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFF5E6673), size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No Holdings Yet',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Go to Explore Stocks to buy your first shares and start building your portfolio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _holdings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _holdings[index];
                  return _buildHoldingTile(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingTile(PositionModel item) {
    return Material(
      color: const Color(0xFF131722),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => StockDetailScreen(
                ticker: item.ticker,
                api: widget.api,
                traderId: widget.traderId,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.ticker,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.shares} shares',
                        style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '₹${item.currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF1E222D), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Avg: ₹${item.avgCost.toStringAsFixed(2)} • LTP: ₹${item.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11),
                  ),
                  Text(
                    '${item.isProfitable ? '+' : ''}₹${item.unrealizedPnL.toStringAsFixed(2)} (${item.isProfitable ? '+' : ''}${item.pnlPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: item.pnlColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
