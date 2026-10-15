import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_numpad.dart';

class BuySellScreen extends StatefulWidget {
  final StockModel stock;
  final String initialSide; // 'BUY' or 'SELL'
  final ApiService api;
  final String traderId;

  const BuySellScreen({
    super.key,
    required this.stock,
    required this.initialSide,
    required this.api,
    required this.traderId,
  });

  @override
  State<BuySellScreen> createState() => _BuySellScreenState();
}

enum ActiveField { price, quantity, threshold }

class _BuySellScreenState extends State<BuySellScreen> {
  late String _side;
  OrderTypeCategory _orderType = OrderTypeCategory.limit;

  String _priceInput = '';
  String _qtyInput = '10';
  String _thresholdInput = '';

  ActiveField _activeField = ActiveField.quantity;

  double _userBalance = 0.0;
  int _userShares = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide.toUpperCase();
    _priceInput = widget.stock.lastTradedPrice.toStringAsFixed(2);
    _thresholdInput = (widget.stock.lastTradedPrice * 0.98).toStringAsFixed(2);
    _fetchAccountAndPortfolio();
  }

  Future<void> _fetchAccountAndPortfolio() async {
    try {
      final bal = await widget.api.getBalance(widget.traderId);
      final portfolio = await widget.api.getPortfolio(widget.traderId);
      int shares = 0;
      for (final p in portfolio) {
        if (p.ticker.toUpperCase() == widget.stock.ticker.toUpperCase()) {
          shares = p.shares;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _userBalance = bal;
          _userShares = shares;
        });
      }
    } catch (_) {
      // silently ignore, balance stays 0
    }
  }

  void _onNumpadKey(String key) {
    setState(() {
      if (_activeField == ActiveField.quantity) {
        if (key == '.') return; // Quantity is whole integer
        if (_qtyInput == '0') _qtyInput = '';
        _qtyInput += key;
      } else if (_activeField == ActiveField.price) {
        if (key == '.' && _priceInput.contains('.')) return;
        if (_priceInput == '0') _priceInput = '';
        _priceInput += key;
      } else if (_activeField == ActiveField.threshold) {
        if (key == '.' && _thresholdInput.contains('.')) return;
        if (_thresholdInput == '0') _thresholdInput = '';
        _thresholdInput += key;
      }
    });
  }

  void _onNumpadBackspace() {
    setState(() {
      if (_activeField == ActiveField.quantity) {
        if (_qtyInput.isNotEmpty) _qtyInput = _qtyInput.substring(0, _qtyInput.length - 1);
        if (_qtyInput.isEmpty) _qtyInput = '0';
      } else if (_activeField == ActiveField.price) {
        if (_priceInput.isNotEmpty) _priceInput = _priceInput.substring(0, _priceInput.length - 1);
        if (_priceInput.isEmpty) _priceInput = '0';
      } else if (_activeField == ActiveField.threshold) {
        if (_thresholdInput.isNotEmpty) _thresholdInput = _thresholdInput.substring(0, _thresholdInput.length - 1);
        if (_thresholdInput.isEmpty) _thresholdInput = '0';
      }
    });
  }

  void _onNumpadClear() {
    setState(() {
      if (_activeField == ActiveField.quantity) {
        _qtyInput = '0';
      } else if (_activeField == ActiveField.price) {
        _priceInput = '0';
      } else if (_activeField == ActiveField.threshold) {
        _thresholdInput = '0';
      }
    });
  }

  Future<void> _submitOrder() async {
    final qty = int.tryParse(_qtyInput) ?? 0;
    if (qty <= 0) {
      _showErrorDialog('Invalid Quantity', 'Please enter a valid share quantity greater than 0.');
      return;
    }

    double price = 0.0;
    if (_orderType == OrderTypeCategory.market) {
      price = widget.stock.lastTradedPrice > 0 ? widget.stock.lastTradedPrice : widget.stock.openPrice;
    } else {
      price = double.tryParse(_priceInput) ?? 0.0;
      if (price <= 0) {
        _showErrorDialog('Invalid Price', 'Please enter a valid limit order price greater than 0.');
        return;
      }
    }

    double? stopThreshold;
    if (_orderType == OrderTypeCategory.stop) {
      stopThreshold = double.tryParse(_thresholdInput);
      if (stopThreshold == null || stopThreshold <= 0) {
        _showErrorDialog('Invalid Stop Threshold', 'Please specify a valid stop threshold trigger price.');
        return;
      }
    }

    // ACID Pre-Validation Checks
    final totalOrderValue = price * qty;
    final estimatedFee = totalOrderValue * 0.001;
    final totalRequiredCash = totalOrderValue + estimatedFee;

    if (_side == 'BUY') {
      if (_userBalance < totalRequiredCash) {
        _showInsufficientFundsDialog(totalRequiredCash, _userBalance);
        return;
      }
    } else if (_side == 'SELL') {
      if (_userShares < qty) {
        _showErrorDialog(
          'Insufficient Shares',
          'You hold $_userShares shares of ${widget.stock.ticker}, but you are trying to sell $qty shares.',
        );
        return;
      }
    }

    String apiType = 'LIMIT';
    if (_orderType == OrderTypeCategory.market) {
      apiType = 'MARKET';
    } else if (_orderType == OrderTypeCategory.stop) {
      apiType = 'STOP_ORDER';
    }

    setState(() => _submitting = true);

    try {
      final res = await widget.api.placeOrder(
        traderId: widget.traderId,
        ticker: widget.stock.ticker,
        side: _side,
        type: apiType,
        price: _orderType == OrderTypeCategory.stop ? (stopThreshold ?? price) : price,
        quantity: qty,
        stopThreshold: stopThreshold,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      final orderId = res['orderId'] ?? 'N/A';
      _showSuccessDialog(orderId, _side, qty, price, apiType);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showErrorDialog('Transaction Rejected', e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF6465D), size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Color(0xFF848E9C))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C087))),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog(double needed, double have) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF0B90B), size: 24),
            SizedBox(width: 8),
            Text('Insufficient Balance', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Required cash: ₹${needed.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
            Text('Available balance: ₹${have.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF6465D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'New users start with ₹0.00 rupees. Please add balance via your Profile icon at the top right to execute transactions.',
              style: TextStyle(color: Color(0xFF848E9C), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF848E9C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C087)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Back to main screen where user can click profile
            },
            child: const Text('Go to Add Balance'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String orderId, String side, int qty, double price, String type) {
    final sideColor = side == 'BUY' ? const Color(0xFF00C087) : const Color(0xFFF6465D);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00C087).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF00C087), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaction Accepted',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'ACID committed order #$orderId',
              style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stock', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      Text(widget.stock.ticker, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Action & Type', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      Text('$side ($type)', style: TextStyle(color: sideColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      Text('$qty shares', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Price', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
                      Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C087),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Back to stock or main
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = _side == 'BUY';
    final activeColor = isBuy ? const Color(0xFF00C087) : const Color(0xFFF6465D);

    final double enteredPrice = _orderType == OrderTypeCategory.market
        ? widget.stock.lastTradedPrice
        : (double.tryParse(_priceInput) ?? 0.0);
    final int enteredQty = int.tryParse(_qtyInput) ?? 0;
    final double totalEstimated = enteredPrice * enteredQty;
    final double estimatedFee = totalEstimated * 0.001;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$_side ${widget.stock.ticker}',
                  style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '₹${widget.stock.lastTradedPrice.toStringAsFixed(2)}',
                    style: TextStyle(color: activeColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Text(widget.stock.companyName, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buy / Sell Side Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _side = 'BUY'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isBuy ? const Color(0xFF00C087) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              color: isBuy ? Colors.white : const Color(0xFF848E9C),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _side = 'SELL'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isBuy ? const Color(0xFFF6465D) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SELL',
                            style: TextStyle(
                              color: !isBuy ? Colors.white : const Color(0xFF848E9C),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Order Type Selector: LIMIT / MARKET / STOP ORDER
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  children: [
                    _buildTypeTab('Limit', OrderTypeCategory.limit),
                    _buildTypeTab('Market', OrderTypeCategory.market),
                    _buildTypeTab('Stop Order', OrderTypeCategory.stop),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Account Available Context Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBuy ? 'Available Cash Balance:' : 'Available Shares Owned:',
                      style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                    ),
                    Text(
                      isBuy ? '₹${_userBalance.toStringAsFixed(2)}' : '$_userShares shares',
                      style: TextStyle(
                        color: isBuy ? const Color(0xFF00C087) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stop Threshold Input (Visible ONLY if Stop Order chosen)
              if (_orderType == OrderTypeCategory.stop) ...[
                _buildInputTile(
                  label: 'Stop Threshold Price (₹)',
                  hint: 'Trigger threshold',
                  value: _thresholdInput,
                  isActive: _activeField == ActiveField.threshold,
                  onTap: () => setState(() => _activeField = ActiveField.threshold),
                  trailingText: 'Trigger',
                ),
                const SizedBox(height: 10),
              ],

              // Price Input (Editable for Limit/Stop, Readonly for Market)
              _buildInputTile(
                label: 'Order Price (₹)',
                hint: _orderType == OrderTypeCategory.market ? 'Market Price' : 'Enter limit price',
                value: _orderType == OrderTypeCategory.market
                    ? '₹${widget.stock.lastTradedPrice.toStringAsFixed(2)}'
                    : _priceInput,
                isActive: _activeField == ActiveField.price && _orderType != OrderTypeCategory.market,
                onTap: _orderType == OrderTypeCategory.market
                    ? null
                    : () => setState(() => _activeField = ActiveField.price),
                trailingText: _orderType == OrderTypeCategory.market ? 'MARKET' : '₹',
              ),
              const SizedBox(height: 10),

              // Quantity Input
              _buildInputTile(
                label: 'Quantity (Shares)',
                hint: 'Enter quantity',
                value: _qtyInput,
                isActive: _activeField == ActiveField.quantity,
                onTap: () => setState(() => _activeField = ActiveField.quantity),
                trailingText: 'SHARES',
              ),
              const SizedBox(height: 12),

              // Live Cost / Revenue Calculation Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Total', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                        Text(
                          '₹${totalEstimated.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Fee (0.1%)', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                        Text('₹${estimatedFee.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tactile On-Screen Numpad
              CustomNumpad(
                onKeyPressed: _onNumpadKey,
                onBackspace: _onNumpadBackspace,
                onClear: _onNumpadClear,
              ),
              const SizedBox(height: 16),

              // Order Submission Button
              ElevatedButton(
                onPressed: _submitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'CONFIRM $_side ${widget.stock.ticker}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, OrderTypeCategory type) {
    final isSelected = _orderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _orderType = type;
            if (type == OrderTypeCategory.market) {
              _activeField = ActiveField.quantity;
            } else if (type == OrderTypeCategory.stop) {
              _activeField = ActiveField.threshold;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A2E39) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF848E9C),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputTile({
    required String label,
    required String hint,
    required String value,
    required bool isActive,
    VoidCallback? onTap,
    required String trailingText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF131722),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00C087) : const Color(0xFF2A2E39),
            width: isActive ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    color: value.isEmpty ? const Color(0xFF5E6673) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailingText,
                style: const TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
