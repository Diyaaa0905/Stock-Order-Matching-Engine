import 'package:flutter/material.dart';

enum OrderSide { buy, sell }

enum OrderTypeCategory { limit, market, stop }

class OrderModel {
  final String id;
  final String traderId;
  final String ticker;
  final OrderSide side;
  final String type;
  final double price;
  final double? stopThreshold;
  final int initialQuantity;
  final int remainingQuantity;
  final int filledQuantity;
  final String status;
  final int timestamp;

  const OrderModel({
    required this.id,
    required this.traderId,
    required this.ticker,
    required this.side,
    required this.type,
    required this.price,
    this.stopThreshold,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.filledQuantity,
    required this.status,
    required this.timestamp,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final sideStr = (json['side'] as String? ?? 'BUY').toUpperCase();
    return OrderModel(
      id: json['id'] as String? ?? '',
      traderId: json['traderId'] as String? ?? '',
      ticker: json['ticker'] as String? ?? '',
      side: sideStr == 'SELL' ? OrderSide.sell : OrderSide.buy,
      type: json['type'] as String? ?? 'LIMIT',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stopThreshold: (json['stopThreshold'] as num?)?.toDouble(),
      initialQuantity: (json['initialQuantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
      filledQuantity: (json['filledQuantity'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String? ?? 'NEW').toUpperCase(),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isOpen => status == 'NEW' || status == 'PARTIALLY_FILLED';
  bool get isFilled => status == 'FILLED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRejected => status == 'REJECTED';

  Color get sideColor => side == OrderSide.buy ? const Color(0xFF00C087) : const Color(0xFFF6465D);

  Color get statusColor {
    switch (status) {
      case 'FILLED':
        return const Color(0xFF00C087);
      case 'NEW':
      case 'PARTIALLY_FILLED':
        return const Color(0xFFF0B90B);
      case 'CANCELLED':
        return const Color(0xFF848E9C);
      case 'REJECTED':
      default:
        return const Color(0xFFF6465D);
    }
  }

  String get formattedDate {
    if (timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
