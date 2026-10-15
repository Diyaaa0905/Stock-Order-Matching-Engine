import 'package:flutter/material.dart';

class PositionModel {
  final String ticker;
  final int shares;
  final double avgCost;
  final double currentPrice;
  final double unrealizedPnL;

  const PositionModel({
    required this.ticker,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.unrealizedPnL,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      ticker: json['ticker'] as String? ?? '',
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      avgCost: (json['avgCost'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      unrealizedPnL: (json['unrealizedPnL'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get totalInvested => avgCost * shares;
  double get currentValue => currentPrice * shares;
  double get pnlPercentage => totalInvested > 0 ? (unrealizedPnL / totalInvested) * 100 : 0.0;
  bool get isProfitable => unrealizedPnL >= 0;
  Color get pnlColor => isProfitable ? const Color(0xFF00C087) : const Color(0xFFF6465D);
}
