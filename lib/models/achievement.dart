import '../utils/app_clock.dart';

enum AchievementId {
  firstEntry,
  tracked7days,
  tracked30days,
  streak3,
  streak7,
  streak14,
  streak30,
  underLimit1,
  underLimit3,
  underLimit7,
  underLimit30,
  reduction10pct,
  reduction25pct,
  reduction50pct,
}

class Achievement {
  final AchievementId id;
  final String emoji;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.emoji,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement unlock([DateTime? at]) => Achievement(
        id: id,
        emoji: emoji,
        unlockedAt: at ?? appNow(),
      );

  static Achievement definition(AchievementId id) => _defs[id]!;

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final id = AchievementId.values.byName(json['id'] as String);
    final base = definition(id);
    final unlockedStr = json['unlockedAt'] as String?;
    return Achievement(
      id: base.id,
      emoji: base.emoji,
      unlockedAt: unlockedStr != null ? DateTime.parse(unlockedStr) : null,
    );
  }

  static const Map<AchievementId, Achievement> _defs = {
    AchievementId.firstEntry: Achievement(
      id: AchievementId.firstEntry,
      emoji: '\u{1F331}',
    ),
    AchievementId.tracked7days: Achievement(
      id: AchievementId.tracked7days,
      emoji: '\u{1F4CA}',
    ),
    AchievementId.tracked30days: Achievement(
      id: AchievementId.tracked30days,
      emoji: '\u{1F4C8}',
    ),
    AchievementId.streak3: Achievement(
      id: AchievementId.streak3,
      emoji: '\u{1F525}',
    ),
    AchievementId.streak7: Achievement(
      id: AchievementId.streak7,
      emoji: '\u2B50',
    ),
    AchievementId.streak14: Achievement(
      id: AchievementId.streak14,
      emoji: '\u{1F31F}',
    ),
    AchievementId.streak30: Achievement(
      id: AchievementId.streak30,
      emoji: '\u{1F3C6}',
    ),
    AchievementId.underLimit1: Achievement(
      id: AchievementId.underLimit1,
      emoji: '\u2705',
    ),
    AchievementId.underLimit3: Achievement(
      id: AchievementId.underLimit3,
      emoji: '\u{1F4AA}',
    ),
    AchievementId.underLimit7: Achievement(
      id: AchievementId.underLimit7,
      emoji: '\u{1F3AF}',
    ),
    AchievementId.underLimit30: Achievement(
      id: AchievementId.underLimit30,
      emoji: '\u{1F451}',
    ),
    AchievementId.reduction10pct: Achievement(
      id: AchievementId.reduction10pct,
      emoji: '\u{1F4C9}',
    ),
    AchievementId.reduction25pct: Achievement(
      id: AchievementId.reduction25pct,
      emoji: '\u{1F680}',
    ),
    AchievementId.reduction50pct: Achievement(
      id: AchievementId.reduction50pct,
      emoji: '\u{1F308}',
    ),
  };
}
