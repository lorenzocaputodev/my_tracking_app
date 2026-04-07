class PackConfig {
  final String name;
  final double totalCost;
  final int pieces;
  final int minutesLost;
  final int dailyLimit;
  final bool tracksInventory;
  final double? directUnitCost;

  const PackConfig({
    required this.name,
    required this.totalCost,
    required this.pieces,
    this.minutesLost = 11,
    this.dailyLimit = 0,
    this.tracksInventory = true,
    this.directUnitCost,
  });

  double get unitCost => tracksInventory
      ? (pieces > 0 ? totalCost / pieces : 0)
      : directUnitCost ?? 0;

  PackConfig copyWith({
    String? name,
    double? totalCost,
    int? pieces,
    int? minutesLost,
    int? dailyLimit,
    bool? tracksInventory,
    double? directUnitCost,
    bool clearDirectUnitCost = false,
  }) {
    return PackConfig(
      name: name ?? this.name,
      totalCost: totalCost ?? this.totalCost,
      pieces: pieces ?? this.pieces,
      minutesLost: minutesLost ?? this.minutesLost,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      tracksInventory: tracksInventory ?? this.tracksInventory,
      directUnitCost:
          clearDirectUnitCost ? null : directUnitCost ?? this.directUnitCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'totalCost': totalCost,
        'pieces': pieces,
        'minutesLost': minutesLost,
        'dailyLimit': dailyLimit,
        'tracksInventory': tracksInventory,
        'directUnitCost': directUnitCost,
      };

  factory PackConfig.fromJson(Map<String, dynamic> json) => PackConfig(
        name: json['name'] as String,
        totalCost: (json['totalCost'] as num).toDouble(),
        pieces: json['pieces'] as int,
        minutesLost: json['minutesLost'] as int? ?? 11,
        dailyLimit: json['dailyLimit'] as int? ?? 0,
        tracksInventory: json['tracksInventory'] as bool? ?? true,
        directUnitCost: (json['directUnitCost'] as num?)?.toDouble(),
      );

  static const PackConfig defaultConfig = PackConfig(
    name: '',
    totalCost: 6.00,
    pieces: 20,
    minutesLost: 11,
    dailyLimit: 0,
    tracksInventory: true,
    directUnitCost: null,
  );
}
