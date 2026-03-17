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

  // 5영역 레이더 차트 데이터 (소통력/설렘지수/안정감/성장가능성/위기관리)
  final Map<String, double>? radarData;

  // MBTI + 사주 합산 전용 필드 (null이면 MBTI만)
  final String? sajuAnalysis;
  final String? myPillar;
  final String? theirPillar;
  final String? overallVerdict;
  final int? destinyScore;     // 천생연분 점수
  final String? pastLifeStory; // 전생 스토리
  final String? bestMonth;     // 최고의 달
  final String? crisisMonth;   // 위기의 달

  // 스킨십 단계 (사주 유료 전용)
  final int? recommendedSkinshipStage;   // 1~7 추천 단계
  final String? skinshipAdvice;          // 스킨십 조언
  final List<String>? datingCourse;     // MBTI 맞춤 데이트 코스
  final String? conflictResolution;     // 갈등 해결법

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
    this.radarData,
    this.sajuAnalysis,
    this.myPillar,
    this.theirPillar,
    this.overallVerdict,
    this.destinyScore,
    this.pastLifeStory,
    this.bestMonth,
    this.crisisMonth,
    this.recommendedSkinshipStage,
    this.skinshipAdvice,
    this.datingCourse,
    this.conflictResolution,
  });

  bool get isSajuMode => sajuAnalysis != null;

  factory MbtiResult.fromJson(Map<String, dynamic> json) => MbtiResult(
    myMbti: json['myMbti'] as String,
    theirMbti: json['theirMbti'] as String,
    compatibilityScore: (json['compatibilityScore'] as num).toInt(),
    compatibilityTag: json['compatibilityTag'] as String? ?? '',
    shockLine: json['shockLine'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    heartPounds: _toStringList(json['heartPounds']),
    dangerZones: _toStringList(json['dangerZones']),
    talkTips: _toStringList(json['talkTips']),
    lovePrediction: json['lovePrediction'] as String? ?? '',
    myPersonality: json['myPersonality'] as String? ?? '',
    theirPersonality: json['theirPersonality'] as String? ?? '',
    radarData: _toRadarData(json['radarData']),
    sajuAnalysis: json['sajuAnalysis'] as String?,
    myPillar: json['myPillar'] as String?,
    theirPillar: json['theirPillar'] as String?,
    overallVerdict: json['overallVerdict'] as String?,
    destinyScore: (json['destinyScore'] as num?)?.toInt(),
    pastLifeStory: json['pastLifeStory'] as String?,
    bestMonth: json['bestMonth'] as String?,
    crisisMonth: json['crisisMonth'] as String?,
    recommendedSkinshipStage: (json['recommendedSkinshipStage'] as num?)?.toInt(),
    skinshipAdvice: json['skinshipAdvice'] as String?,
    datingCourse: _toStringList(json['datingCourse']),
    conflictResolution: json['conflictResolution'] as String?,
  );

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static Map<String, double>? _toRadarData(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return null;
  }
}
