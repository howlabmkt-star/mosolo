class MbtiResult {
  final String myMbti;
  final String theirMbti;
  final int compatibilityScore; // 0~100
  final String shockLine;       // 팩폭 한 줄
  final String summary;

  const MbtiResult({
    required this.myMbti,
    required this.theirMbti,
    required this.compatibilityScore,
    required this.shockLine,
    required this.summary,
  });

  factory MbtiResult.fromJson(Map<String, dynamic> json) => MbtiResult(
    myMbti: json['myMbti'] as String,
    theirMbti: json['theirMbti'] as String,
    compatibilityScore: json['compatibilityScore'] as int,
    shockLine: json['shockLine'] as String,
    summary: json['summary'] as String,
  );
}
