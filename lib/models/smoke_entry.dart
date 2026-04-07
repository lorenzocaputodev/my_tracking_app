class SmokeEntry {
  final String id;
  final DateTime timestamp;
  final double costDeducted;
  final int minutesLost;
  final String productId;

  const SmokeEntry({
    required this.id,
    required this.timestamp,
    required this.costDeducted,
    required this.minutesLost,
    this.productId = 'default',
  });

  DateTime get dateOnly =>
      DateTime(timestamp.year, timestamp.month, timestamp.day);

  SmokeEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? costDeducted,
    int? minutesLost,
    String? productId,
  }) {
    return SmokeEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      costDeducted: costDeducted ?? this.costDeducted,
      minutesLost: minutesLost ?? this.minutesLost,
      productId: productId ?? this.productId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'costDeducted': costDeducted,
        'minutesLost': minutesLost,
        'productId': productId,
      };

  factory SmokeEntry.fromJson(Map<String, dynamic> json) => SmokeEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        costDeducted: (json['costDeducted'] as num).toDouble(),
        minutesLost: json['minutesLost'] as int? ?? 0,
        productId: json['productId'] as String? ?? 'default',
      );
}
