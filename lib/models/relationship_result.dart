class RelationshipResult {
  final int temperature;
  final String sincerity; // 진심|애매|관심없음
  final String sincerityReason;
  final List<String> positiveSignals;
  final List<String> warningSignals;
  final String shockLine;

  // 사주 심층 분석 전용 (null이면 무료)
  final String? relationshipType;       // 귀인|악연|인연|시험|스침
  final String? relationshipTypeReason;
  final String? futureFlow;
  final String? bestTiming;
  final String? finalVerdict;
  final String? adviceForUser;

  const RelationshipResult({
    required this.temperature,
    required this.sincerity,
    required this.sincerityReason,
    this.positiveSignals = const [],
    this.warningSignals = const [],
    this.shockLine = '',
    this.relationshipType,
    this.relationshipTypeReason,
    this.futureFlow,
    this.bestTiming,
    this.finalVerdict,
    this.adviceForUser,
  });

  bool get isSajuMode => relationshipType != null;

  factory RelationshipResult.fromJson(Map<String, dynamic> json) => RelationshipResult(
    temperature: (json['temperature'] as num).toInt(),
    sincerity: json['sincerity'] as String? ?? '애매',
    sincerityReason: json['sincerityReason'] as String? ?? '',
    positiveSignals: _toList(json['positiveSignals']),
    warningSignals: _toList(json['warningSignals']),
    shockLine: json['shockLine'] as String? ?? '',
    relationshipType: json['relationshipType'] as String?,
    relationshipTypeReason: json['relationshipTypeReason'] as String?,
    futureFlow: json['futureFlow'] as String?,
    bestTiming: json['bestTiming'] as String?,
    finalVerdict: json['finalVerdict'] as String?,
    adviceForUser: json['adviceForUser'] as String?,
  );

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
