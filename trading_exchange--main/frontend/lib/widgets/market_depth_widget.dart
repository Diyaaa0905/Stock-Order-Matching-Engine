import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order_book_model.dart';

class MarketDepthWidget extends StatelessWidget {
  final OrderBookModel? book;
  final Function(double price)? onPriceSelected;

  const MarketDepthWidget({
    super.key,
    required this.book,
    this.onPriceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF00C087)),
        ),
      );
    }

    final bids = book!.bids;
    final asks = book!.asks;
    final int rowsCount = max(bids.length, asks.length);
    final int maxQty = max(max(book!.maxBidQty, book!.maxAskQty), 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
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
              const Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: Color(0xFF848E9C)),
                  SizedBox(width: 6),
                  Text(
                    'Market Depth (Order Book)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'LTP: ₹${book!.lastPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF00C087),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Column Headers
          const Row(
            children: [
              // Bids Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BID QTY', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('BID PRICE (₹)', style: TextStyle(color: Color(0xFF00C087), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Asks Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ASK PRICE (₹)', style: TextStyle(color: Color(0xFFF6465D), fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('ASK QTY', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2A2E39), height: 16),

          // Depth rows
          if (rowsCount == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No active orders in book', style: TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rowsCount,
              itemBuilder: (context, index) {
                final bid = index < bids.length ? bids[index] : null;
                final ask = index < asks.length ? asks[index] : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      // Bid side (Green)
                      Expanded(
                        child: bid != null
                            ? _buildDepthRow(
                                isBid: true,
                                price: bid.price,
                                qty: bid.quantity,
                                maxQty: maxQty,
                                onTap: () => onPriceSelected?.call(bid.price),
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 16),
                      // Ask side (Red)
                      Expanded(
                        child: ask != null
                            ? _buildDepthRow(
                                isBid: false,
                                price: ask.price,
                                qty: ask.quantity,
                                maxQty: maxQty,
                                onTap: () => onPriceSelected?.call(ask.price),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 8),
          // Total volumes summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bids: ${book!.totalBidVolume}', style: const TextStyle(color: Color(0xFF00C087), fontSize: 11, fontWeight: FontWeight.w500)),
              Text('Total Asks: ${book!.totalAskVolume}', style: const TextStyle(color: Color(0xFFF6465D), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepthRow({
    required bool isBid,
    required double price,
    required int qty,
    required int maxQty,
    required VoidCallback onTap,
  }) {
    final double ratio = (qty / maxQty).clamp(0.05, 1.0);
    final color = isBid ? const Color(0xFF00C087) : const Color(0xFFF6465D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        alignment: isBid ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // Depth volume bar
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Row Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: isBid
                  ? [
                      Text(
                        qty.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ]
                  : [
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        qty.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
