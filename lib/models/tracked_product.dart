import 'package:uuid/uuid.dart';

class TrackedProduct {
  final String id;
  final String name;
  final double totalCost;
  final int pieces;
  final int minutesLost;
  final int dailyLimit;
  final int packRemaining;
  final bool tracksInventory;
  final double? directUnitCost;
  final bool isArchived;

  const TrackedProduct({
    required this.id,
    required this.name,
    required this.totalCost,
    required this.pieces,
    this.minutesLost = 11,
    this.dailyLimit = 0,
    this.packRemaining = 0,
    this.tracksInventory = true,
    this.directUnitCost,
    this.isArchived = false,
  });

  double get unitCost => tracksInventory
      ? (pieces > 0 ? totalCost / pieces : 0)
      : directUnitCost ?? 0;

  TrackedProduct copyWith({
    String? id,
    String? name,
    double? totalCost,
    int? pieces,
    int? minutesLost,
    int? dailyLimit,
    int? packRemaining,
    bool? tracksInventory,
    double? directUnitCost,
    bool clearDirectUnitCost = false,
    bool? isArchived,
  }) {
    return TrackedProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      totalCost: totalCost ?? this.totalCost,
      pieces: pieces ?? this.pieces,
      minutesLost: minutesLost ?? this.minutesLost,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      packRemaining: packRemaining ?? this.packRemaining,
      tracksInventory: tracksInventory ?? this.tracksInventory,
      directUnitCost:
          clearDirectUnitCost ? null : directUnitCost ?? this.directUnitCost,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalCost': totalCost,
        'pieces': pieces,
        'minutesLost': minutesLost,
        'dailyLimit': dailyLimit,
        'packRemaining': packRemaining,
        'tracksInventory': tracksInventory,
        'directUnitCost': directUnitCost,
        'isArchived': isArchived,
      };

  factory TrackedProduct.fromJson(Map<String, dynamic> json) => TrackedProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        totalCost: (json['totalCost'] as num).toDouble(),
        pieces: json['pieces'] as int,
        minutesLost: json['minutesLost'] as int? ?? 11,
        dailyLimit: json['dailyLimit'] as int? ?? 0,
        packRemaining: json['packRemaining'] as int? ?? 0,
        tracksInventory: json['tracksInventory'] as bool? ?? true,
        directUnitCost: (json['directUnitCost'] as num?)?.toDouble(),
        isArchived: json['isArchived'] as bool? ?? false,
      );

  static TrackedProduct fromLegacyPackConfig({
    required dynamic legacyJson,
    int packRemaining = 0,
  }) {
    final m = legacyJson as Map<String, dynamic>;
    return TrackedProduct(
      id: 'default',
      name: m['name'] as String,
      totalCost: (m['totalCost'] as num).toDouble(),
      pieces: m['pieces'] as int,
      minutesLost: m['minutesLost'] as int? ?? 11,
      dailyLimit: m['dailyLimit'] as int? ?? 0,
      packRemaining: packRemaining,
      tracksInventory: true,
      isArchived: false,
    );
  }

  static TrackedProduct createNew({
    required String name,
    required double totalCost,
    required int pieces,
    int minutesLost = 11,
    int dailyLimit = 0,
    bool tracksInventory = true,
    double? directUnitCost,
  }) {
    return TrackedProduct(
      id: const Uuid().v4(),
      name: name,
      totalCost: totalCost,
      pieces: pieces,
      minutesLost: minutesLost,
      dailyLimit: dailyLimit,
      packRemaining: pieces,
      tracksInventory: tracksInventory,
      directUnitCost: directUnitCost,
      isArchived: false,
    );
  }
}
