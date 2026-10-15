class ChartPointModel {
  final int timestamp;
  final double price;
  final int volume;

  const ChartPointModel({
    required this.timestamp,
    required this.price,
    this.volume = 0,
  });

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }
}
