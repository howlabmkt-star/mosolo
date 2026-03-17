class SkinshipStage {
  final int stage;        // 1~7
  final String emoji;
  final String title;
  final String description;
  final String timing;    // "지금 바로" | "2~3주 후" | "1개월 후" 등
  final String tip;
  final bool isRecommended;

  const SkinshipStage({
    required this.stage,
    required this.emoji,
    required this.title,
    required this.description,
    required this.timing,
    required this.tip,
    this.isRecommended = false,
  });
}

class CompatibilityResult {
  final int compatibilityScore;   // 0~100
  final String temperatureLabel;  // "불타는 인연" | "따뜻한 인연" | "미지근한 인연" | "차가운 인연"
  final String compatibilityTag;
  final String shockLine;
  final String summary;

  // 무료 범위
  final String myElementDesc;     // 나의 오행 특성
  final String theirElementDesc;  // 상대방 오행 특성

  // 유료 전용 (null이면 미결제)
  final List<SkinshipStage>? skinshipStages;
  final int? recommendedStageIndex;         // 현재 추천 단계 (0-based)
  final List<String>? datingAdvice;         // 연애 조언 3가지
  final String? thisMonthFortune;           // 이달의 운세
  final String? bestDateIdea;              // 추천 데이트 코스
  final String? conflictResolution;        // 갈등 해결법
  final String? coupleChemistry;           // 케미 분석

  const CompatibilityResult({
    required this.compatibilityScore,
    required this.temperatureLabel,
    required this.compatibilityTag,
    required this.shockLine,
    required this.summary,
    required this.myElementDesc,
    required this.theirElementDesc,
    this.skinshipStages,
    this.recommendedStageIndex,
    this.datingAdvice,
    this.thisMonthFortune,
    this.bestDateIdea,
    this.conflictResolution,
    this.coupleChemistry,
  });

  bool get isPremium => skinshipStages != null;

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) {
    List<SkinshipStage>? stages;
    if (json['skinshipStages'] != null) {
      final raw = json['skinshipStages'] as List;
      stages = raw.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value as Map;
        final recommended = (json['recommendedStageIndex'] as num?)?.toInt() == i;
        return SkinshipStage(
          stage: i + 1,
          emoji: s['emoji'] as String? ?? '💑',
          title: s['title'] as String? ?? '',
          description: s['description'] as String? ?? '',
          timing: s['timing'] as String? ?? '',
          tip: s['tip'] as String? ?? '',
          isRecommended: recommended,
        );
      }).toList();
    }

    return CompatibilityResult(
      compatibilityScore: (json['compatibilityScore'] as num).toInt(),
      temperatureLabel: json['temperatureLabel'] as String? ?? '따뜻한 인연',
      compatibilityTag: json['compatibilityTag'] as String? ?? '',
      shockLine: json['shockLine'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      myElementDesc: json['myElementDesc'] as String? ?? '',
      theirElementDesc: json['theirElementDesc'] as String? ?? '',
      skinshipStages: stages,
      recommendedStageIndex: (json['recommendedStageIndex'] as num?)?.toInt(),
      datingAdvice: _toStringList(json['datingAdvice']),
      thisMonthFortune: json['thisMonthFortune'] as String?,
      bestDateIdea: json['bestDateIdea'] as String?,
      conflictResolution: json['conflictResolution'] as String?,
      coupleChemistry: json['coupleChemistry'] as String?,
    );
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }
}
