class MbtiResult {
  final String myMbti;
  final String theirMbti;
  final int compatibilityScore;
  final String compatibilityTag;
  final String shockLine;
  final String summary;
  final List<String> heartPounds;
  final List<String> dangerZones;
  final List<String> talkTips;
  final String lovePrediction;
  final String myPersonality;
  final String theirPersonality;

  // MBTI + 사주 합산 전용 필드 (null이면 MBTI만)
  final String? sajuAnalysis;
  final String? myPillar;
  final String? theirPillar;
  final String? overallVerdict;

  const MbtiResult({
    required this.myMbti,
    required this.theirMbti,
    required this.compatibilityScore,
    this.compatibilityTag = '',
    required this.shockLine,
    required this.summary,
    this.heartPounds = const [],
    this.dangerZones = const [],
    this.talkTips = const [],
    this.lovePrediction = '',
    this.myPersonality = '',
    this.theirPersonality = '',
    this.sajuAnalysis,
    this.myPillar,
    this.theirPillar,
    this.overallVerdict,
  });

  bool get isSajuMode => sajuAnalysis != null;

  factory MbtiResult.fromJson(Map<String, dynamic> json) => MbtiResult(
    myMbti: json['myMbti'] as String,
    theirMbti: json['theirMbti'] as String,
    compatibilityScore: json['compatibilityScore'] as int,
    compatibilityTag: json['compatibilityTag'] as String? ?? '',
    shockLine: json['shockLine'] as String,
    summary: json['summary'] as String,
    heartPounds: _toStringList(json['heartPounds']),
    dangerZones: _toStringList(json['dangerZones']),
    talkTips: _toStringList(json['talkTips']),
    lovePrediction: json['lovePrediction'] as String? ?? '',
    myPersonality: json['myPersonality'] as String? ?? '',
    theirPersonality: json['theirPersonality'] as String? ?? '',
    sajuAnalysis: json['sajuAnalysis'] as String?,
    myPillar: json['myPillar'] as String?,
    theirPillar: json['theirPillar'] as String?,
    overallVerdict: json['overallVerdict'] as String?,
  );

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
