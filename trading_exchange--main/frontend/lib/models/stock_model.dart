import 'package:flutter/material.dart';

class StockModel {
  final String ticker;
  final String companyName;
  final double tickSize;
  final int initialShares;
  final bool tradingPaused;
  final double lastTradedPrice;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final int volume;
  final double growth;
  final double change;

  const StockModel({
    required this.ticker,
    required this.companyName,
    required this.tickSize,
    required this.initialShares,
    required this.tradingPaused,
    required this.lastTradedPrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.growth,
    required this.change,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    final lastPrice = (json['lastTradedPrice'] as num?)?.toDouble() ?? 0.0;
    final open = (json['openPrice'] as num?)?.toDouble() ?? lastPrice;
    final calculatedGrowth = open > 0 ? ((lastPrice - open) / open) * 100 : 0.0;
    final growthVal = (json['growth'] as num?)?.toDouble() ?? calculatedGrowth;
    final changeVal = (json['change'] as num?)?.toDouble() ?? (lastPrice - open);

    return StockModel(
      ticker: json['ticker'] as String? ?? '',
      companyName: json['companyName'] as String? ?? (json['ticker'] as String? ?? ''),
      tickSize: (json['tickSize'] as num?)?.toDouble() ?? 0.05,
      initialShares: (json['initialShares'] as num?)?.toInt() ?? 100,
      tradingPaused: json['tradingPaused'] as bool? ?? false,
      lastTradedPrice: lastPrice,
      openPrice: open,
      highPrice: (json['highPrice'] as num?)?.toDouble() ?? lastPrice,
      lowPrice: (json['lowPrice'] as num?)?.toDouble() ?? lastPrice,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      growth: growthVal,
      change: changeVal,
    );
  }

  bool get isPositive => growth >= 0;

  Color get color => isPositive ? const Color(0xFF00C087) : const Color(0xFFF6465D);

  String get formattedPrice => '₹${lastTradedPrice.toStringAsFixed(2)}';

  String get formattedChange => '${isPositive ? '+' : ''}₹${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${growth.toStringAsFixed(2)}%)';
}
