import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../models/order_book_model.dart';
import '../models/chart_point_model.dart';
import '../services/api_service.dart';
import '../widgets/stock_chart_widget.dart';
import '../widgets/market_depth_widget.dart';
import 'buy_sell_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;
  final ApiService api;
  final String traderId;

  const StockDetailScreen({
    super.key,
    required this.ticker,
    required this.api,
    required this.traderId,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockModel? _stock;
  OrderBookModel? _book;
  List<ChartPointModel> _chartPoints = [];
  String _activeTimeframe = '1D';

  bool _loading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshLiveStats());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchStockInfo(),
      _fetchOrderBook(),
      _fetchChartData(_activeTimeframe),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshLiveStats() async {
    await Future.wait([
      _fetchStockInfo(),
      _fetchOrderBook(),
    ]);
  }

  Future<void> _fetchStockInfo() async {
    try {
      final stocks = await widget.api.getStocks();
      final match = stocks.firstWhere(
        (s) => s.ticker.toUpperCase() == widget.ticker.toUpperCase(),
        orElse: () => _stock ?? StockModel(
          ticker: widget.ticker,
          companyName: widget.ticker,
          tickSize: 0.05,
          initialShares: 100,
          tradingPaused: false,
          lastTradedPrice: 100.0,
          openPrice: 100.0,
          highPrice: 100.0,
          lowPrice: 100.0,
          volume: 100,
          growth: 0.0,
          change: 0.0,
        ),
      );
      if (mounted) setState(() => _stock = match);
    } catch (_) {}
  }

  Future<void> _fetchOrderBook() async {
    try {
      final book = await widget.api.getOrderBook(widget.ticker);
      if (mounted) setState(() => _book = book);
    } catch (_) {}
  }

  Future<void> _fetchChartData(String timeframe) async {
    try {
      final points = await widget.api.getChartData(widget.ticker, timeframe);
      if (mounted) {
        setState(() {
          _chartPoints = points;
          _activeTimeframe = timeframe;
        });
      }
    } catch (_) {}
  }

  void _navigateToOrder(String side) {
    if (_stock == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BuySellScreen(
          stock: _stock!,
          initialSide: side,
          api: widget.api,
          traderId: widget.traderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stock;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticker,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (stock != null)
              Text(
                stock.companyName,
                style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF848E9C)),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _loading && stock == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C087)))
          : stock == null
              ? const Center(child: Text('Stock data not available', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Price & Growth Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: const Color(0xFF131722),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stock.formattedPrice,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      stock.isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                      color: stock.color,
                                      size: 20,
                                    ),
                                    Text(
                                      stock.formattedChange,
                                      style: TextStyle(
                                        color: stock.color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Circuit Breaker or Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: stock.tradingPaused
                                    ? const Color(0xFFF6465D).withValues(alpha: 0.15)
                                    : const Color(0xFF00C087).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: stock.tradingPaused ? const Color(0xFFF6465D) : const Color(0xFF00C087),
                                ),
                              ),
                              child: Text(
                                stock.tradingPaused ? 'HALTED' : 'ACTIVE',
                                style: TextStyle(
                                  color: stock.tradingPaused ? const Color(0xFFF6465D) : const Color(0xFF00C087),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Interactive Chart with 1D, 1M, 1Y, ALL
                      StockChartWidget(
                        points: _chartPoints,
                        activeTimeframe: _activeTimeframe,
                        onTimeframeChanged: (tf) => _fetchChartData(tf),
                        isPositive: stock.isPositive,
                      ),
                      const SizedBox(height: 12),

                      // Market Stats Grid (Day High, Day Low, Volume, Initial Shares)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCol('Open Price', '₹${stock.openPrice.toStringAsFixed(2)}'),
                                _buildStatCol('Day High', '₹${stock.highPrice.toStringAsFixed(2)}'),
                                _buildStatCol('Day Low', '₹${stock.lowPrice.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(color: Color(0xFF2A2E39), height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCol('24h Volume', '${stock.volume} shs'),
                                _buildStatCol('Initial Shares', '${stock.initialShares} shs'),
                                _buildStatCol('Tick Size', '₹${stock.tickSize.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Market Depth Ladder (Bids & Asks with Qty & Price)
                      MarketDepthWidget(
                        book: _book,
                        onPriceSelected: (price) {
                          // Quick autofill order price
                          _navigateToOrder('BUY');
                        },
                      ),
                      const SizedBox(height: 80), // spacing for bottom bar
                    ],
                  ),
                ),
      // Bottom Action Bar with BUY and SELL buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF131722),
          border: Border(top: BorderSide(color: Color(0xFF2A2E39))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToOrder('BUY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C087),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, size: 18),
                      SizedBox(width: 6),
                      Text('BUY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToOrder('SELL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6465D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, size: 18),
                      SizedBox(width: 6),
                      Text('SELL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
