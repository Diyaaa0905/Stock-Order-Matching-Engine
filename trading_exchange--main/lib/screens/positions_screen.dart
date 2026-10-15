import 'package:flutter/material.dart';
import '../models/position_model.dart';
import '../services/api_service.dart';
import 'stock_detail_screen.dart';

class PositionsScreen extends StatefulWidget {
  final ApiService api;
  final String traderId;

  const PositionsScreen({
    super.key,
    required this.api,
    required this.traderId,
  });

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  List<PositionModel> _positions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.getPortfolio(widget.traderId);
      if (mounted) {
        setState(() {
          _positions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPnL = 0;
    for (final p in _positions) {
      totalPnL += p.unrealizedPnL;
    }
    final isProfitable = totalPnL >= 0;

    return RefreshIndicator(
      color: const Color(0xFF00C087),
      backgroundColor: const Color(0xFF131722),
      onRefresh: _fetchPositions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // P&L Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Unrealized P&L', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Active Intraday / Open Positions', style: TextStyle(color: Color(0xFF5E6673), fontSize: 10)),
                    ],
                  ),
                  Text(
                    '${isProfitable ? '+' : ''}₹${totalPnL.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isProfitable ? const Color(0xFF00C087) : const Color(0xFFF6465D),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OPEN POSITIONS (${_positions.length})',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF848E9C), size: 18),
                  onPressed: _fetchPositions,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading && _positions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF00C087))))
            else if (_positions.isEmpty)
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
                    Icon(Icons.query_stats, color: Color(0xFF5E6673), size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No Active Open Positions',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Execute buy or sell orders in Explore Stocks to open live market trading positions.',
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
                itemCount: _positions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pos = _positions[index];
                  return _buildPositionTile(pos);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionTile(PositionModel pos) {
    return Material(
      color: const Color(0xFF131722),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => StockDetailScreen(
                ticker: pos.ticker,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C087).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('LONG', style: TextStyle(color: Color(0xFF00C087), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pos.ticker,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Text(
                    '${pos.shares} Qty',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entry: ₹${pos.avgCost.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                  Text('LTP: ₹${pos.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                  Text(
                    '${pos.isProfitable ? '+' : ''}₹${pos.unrealizedPnL.toStringAsFixed(2)}',
                    style: TextStyle(color: pos.pnlColor, fontWeight: FontWeight.bold, fontSize: 13),
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
