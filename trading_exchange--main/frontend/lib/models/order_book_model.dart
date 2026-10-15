class BookEntry {
  final double price;
  final int quantity;
  final int count;

  const BookEntry({
    required this.price,
    required this.quantity,
    this.count = 1,
  });

  factory BookEntry.fromJson(Map<String, dynamic> json) {
    return BookEntry(
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderBookModel {
  final String ticker;
  final String companyName;
  final bool tradingPaused;
  final double lastPrice;
  final List<BookEntry> bids;
  final List<BookEntry> asks;

  const OrderBookModel({
    required this.ticker,
    required this.companyName,
    required this.tradingPaused,
    required this.lastPrice,
    required this.bids,
    required this.asks,
  });

  factory OrderBookModel.fromJson(Map<String, dynamic> json) {
    final bidsList = (json['bids'] as List<dynamic>? ?? [])
        .map((e) => BookEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final asksList = (json['asks'] as List<dynamic>? ?? [])
        .map((e) => BookEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderBookModel(
      ticker: json['ticker'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      tradingPaused: json['tradingPaused'] as bool? ?? false,
      lastPrice: (json['lastPrice'] as num?)?.toDouble() ?? 0.0,
      bids: bidsList,
      asks: asksList,
    );
  }

  int get maxBidQty => bids.fold<int>(0, (prev, e) => e.quantity > prev ? e.quantity : prev);
  int get maxAskQty => asks.fold<int>(0, (prev, e) => e.quantity > prev ? e.quantity : prev);
  int get totalBidVolume => bids.fold<int>(0, (prev, e) => prev + e.quantity);
  int get totalAskVolume => asks.fold<int>(0, (prev, e) => prev + e.quantity);
}
