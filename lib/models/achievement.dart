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
  final String title;
  final String description;
  final String emoji;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement unlock() => Achievement(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        unlockedAt: DateTime.now(),
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
      title: base.title,
      description: base.description,
      emoji: base.emoji,
      unlockedAt: unlockedStr != null ? DateTime.parse(unlockedStr) : null,
    );
  }

  static const Map<AchievementId, Achievement> _defs = {
    AchievementId.firstEntry: Achievement(
      id: AchievementId.firstEntry,
      emoji: '\u{1F331}',
      title: 'Prima tracciata',
      description: 'Hai registrato la prima unit\u00E0.',
    ),
    AchievementId.tracked7days: Achievement(
      id: AchievementId.tracked7days,
      emoji: '\u{1F4CA}',
      title: '7 giorni di dati',
      description: 'Attivit\u00E0 registrata per 7 giorni distinti.',
    ),
    AchievementId.tracked30days: Achievement(
      id: AchievementId.tracked30days,
      emoji: '\u{1F4C8}',
      title: '30 giorni di dati',
      description: 'Attivit\u00E0 registrata per 30 giorni distinti.',
    ),
    AchievementId.streak3: Achievement(
      id: AchievementId.streak3,
      emoji: '\u{1F525}',
      title: '3 giorni di fila',
      description: 'Attivo 3 giorni consecutivi.',
    ),
    AchievementId.streak7: Achievement(
      id: AchievementId.streak7,
      emoji: '\u2B50',
      title: 'Settimana intera',
      description: 'Attivo 7 giorni consecutivi.',
    ),
    AchievementId.streak14: Achievement(
      id: AchievementId.streak14,
      emoji: '\u{1F31F}',
      title: 'Due settimane',
      description: 'Attivo 14 giorni consecutivi.',
    ),
    AchievementId.streak30: Achievement(
      id: AchievementId.streak30,
      emoji: '\u{1F3C6}',
      title: 'Un mese intero',
      description: 'Attivo 30 giorni consecutivi.',
    ),
    AchievementId.underLimit1: Achievement(
      id: AchievementId.underLimit1,
      emoji: '\u2705',
      title: 'Primo giorno ok',
      description: '1 giorno sotto il limite giornaliero.',
    ),
    AchievementId.underLimit3: Achievement(
      id: AchievementId.underLimit3,
      emoji: '\u{1F4AA}',
      title: 'Tre giorni ok',
      description: '3 giorni consecutivi sotto il limite.',
    ),
    AchievementId.underLimit7: Achievement(
      id: AchievementId.underLimit7,
      emoji: '\u{1F3AF}',
      title: 'Settimana ok',
      description: '7 giorni consecutivi sotto il limite.',
    ),
    AchievementId.underLimit30: Achievement(
      id: AchievementId.underLimit30,
      emoji: '\u{1F451}',
      title: 'Mese sotto controllo',
      description: '30 giorni consecutivi sotto il limite.',
    ),
    AchievementId.reduction10pct: Achievement(
      id: AchievementId.reduction10pct,
      emoji: '\u{1F4C9}',
      title: '-10% media',
      description: 'Media ridotta del 10% rispetto all\'inizio del piano.',
    ),
    AchievementId.reduction25pct: Achievement(
      id: AchievementId.reduction25pct,
      emoji: '\u{1F680}',
      title: '-25% media',
      description: 'Media ridotta del 25% rispetto all\'inizio del piano.',
    ),
    AchievementId.reduction50pct: Achievement(
      id: AchievementId.reduction50pct,
      emoji: '\u{1F308}',
      title: '-50% media',
      description: 'Hai dimezzato la tua media. Eccezionale!',
    ),
  };
}
