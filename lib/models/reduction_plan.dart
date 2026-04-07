class ReductionPlan {
  final String productId;
  final double startAverage;
  final double targetPerDay;
  final int totalWeeks;
  final DateTime startDate;

  const ReductionPlan({
    required this.productId,
    required this.startAverage,
    required this.targetPerDay,
    required this.totalWeeks,
    required this.startDate,
  });

  int get weeksPassed => DateTime.now().difference(startDate).inDays ~/ 7;

  bool get isCompleted => weeksPassed >= totalWeeks;

  double get progressFraction => (weeksPassed / totalWeeks).clamp(0.0, 1.0);

  double get currentWeekTarget {
    if (isCompleted) return targetPerDay;
    return startAverage - (startAverage - targetPerDay) * progressFraction;
  }

  int get currentWeekNumber => (weeksPassed + 1).clamp(1, totalWeeks);

  int get daysRemaining {
    final endDate = startDate.add(Duration(days: totalWeeks * 7));
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  ReductionPlan copyWith({
    String? productId,
    double? startAverage,
    double? targetPerDay,
    int? totalWeeks,
    DateTime? startDate,
  }) {
    return ReductionPlan(
      productId: productId ?? this.productId,
      startAverage: startAverage ?? this.startAverage,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      startDate: startDate ?? this.startDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'startAverage': startAverage,
        'targetPerDay': targetPerDay,
        'totalWeeks': totalWeeks,
        'startDate': startDate.toIso8601String(),
      };

  factory ReductionPlan.fromJson(Map<String, dynamic> json) => ReductionPlan(
        productId: json['productId'] as String? ?? '',
        startAverage: (json['startAverage'] as num).toDouble(),
        targetPerDay: (json['targetPerDay'] as num).toDouble(),
        totalWeeks: json['totalWeeks'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
      );
}
