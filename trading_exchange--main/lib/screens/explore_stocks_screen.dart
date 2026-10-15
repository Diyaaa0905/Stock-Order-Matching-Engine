import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../services/api_service.dart';
import 'stock_detail_screen.dart';

class ExploreStocksScreen extends StatefulWidget {
  final ApiService api;
  final String traderId;

  const ExploreStocksScreen({
    super.key,
    required this.api,
    required this.traderId,
  });

  @override
  State<ExploreStocksScreen> createState() => _ExploreStocksScreenState();
}

class _ExploreStocksScreenState extends State<ExploreStocksScreen> {
  List<StockModel> _stocks = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchStocks();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStocks(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStocks({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final stocks = await widget.api.getStocks();
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _stocks.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.ticker.toLowerCase().contains(q) || s.companyName.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF00C087),
      backgroundColor: const Color(0xFF131722),
      onRefresh: () => _fetchStocks(),
      child: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search stocks, companies, indices...',
                hintStyle: const TextStyle(color: Color(0xFF5E6673), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF848E9C), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF848E9C), size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF131722),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C087)),
                ),
              ),
            ),
          ),

          // Markets status header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ALL LISTED MARKETS (${filtered.length})',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF00C087), size: 8),
                    SizedBox(width: 4),
                    Text('Live Depth Active', style: TextStyle(color: Color(0xFF00C087), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // List of Stocks
          Expanded(
            child: _loading && _stocks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C087)))
                : _error != null && _stocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFF6465D), size: 36),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: Color(0xFF848E9C))),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _fetchStocks(),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C087)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching stocks found.',
                              style: TextStyle(color: Color(0xFF848E9C)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final stock = filtered[index];
                              return _buildStockCard(stock);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockModel stock) {
    return Material(
      color: const Color(0xFF131722),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => StockDetailScreen(
                ticker: stock.ticker,
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
          child: Row(
            children: [
              // Stock Ticker & Initial Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                alignment: Alignment.center,
                child: Text(
                  stock.ticker.length > 3 ? stock.ticker.substring(0, 3) : stock.ticker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Stock Names & Initial Shares Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.ticker,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Initial shares present badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E222D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2A2E39)),
                          ),
                          child: Text(
                            '${stock.initialShares} shs',
                            style: const TextStyle(color: Color(0xFF848E9C), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF848E9C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Price & Growth badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stock.formattedPrice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stock.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stock.isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: stock.color,
                          size: 16,
                        ),
                        Text(
                          '${stock.growth >= 0 ? '+' : ''}${stock.growth.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: stock.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
