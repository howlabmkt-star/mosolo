class AnalysisResult {
  final int score;          // 호감도 0~100
  final String summary;     // 한 줄 요약 (무료)

  // 유료 전용 필드
  final List<ReplyPattern>? replyPatterns;   // 답장 대기시간
  final List<Keyword>? keywords;             // 키워드
  final List<EmotionPoint>? emotionChart;    // 감정 그래프
  final String? aiGuide;                     // AI 대화 가이드
  final String? prediction;                  // 관계 발전 예측

  const AnalysisResult({
    required this.score,
    required this.summary,
    this.replyPatterns,
    this.keywords,
    this.emotionChart,
    this.aiGuide,
    this.prediction,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    score: json['score'] as int,
    summary: json['summary'] as String,
    replyPatterns: (json['replyPatterns'] as List<dynamic>?)
      ?.map((e) => ReplyPattern.fromJson(e as Map<String, dynamic>))
      .toList(),
    keywords: (json['keywords'] as List<dynamic>?)
      ?.map((e) => Keyword.fromJson(e as Map<String, dynamic>))
      .toList(),
    emotionChart: (json['emotionChart'] as List<dynamic>?)
      ?.map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
    aiGuide: json['aiGuide'] as String?,
    prediction: json['prediction'] as String?,
  );
}

class ReplyPattern {
  final String label;
  final double avgMinutes;

  const ReplyPattern({required this.label, required this.avgMinutes});

  factory ReplyPattern.fromJson(Map<String, dynamic> json) => ReplyPattern(
    label: json['label'] as String,
    avgMinutes: (json['avgMinutes'] as num).toDouble(),
  );
}

class Keyword {
  final String word;
  final int count;
  final String sentiment; // 'positive' | 'negative' | 'neutral'

  const Keyword({required this.word, required this.count, required this.sentiment});

  factory Keyword.fromJson(Map<String, dynamic> json) => Keyword(
    word: json['word'] as String,
    count: json['count'] as int,
    sentiment: json['sentiment'] as String,
  );
}

class EmotionPoint {
  final String date;
  final double score;

  const EmotionPoint({required this.date, required this.score});

  factory EmotionPoint.fromJson(Map<String, dynamic> json) => EmotionPoint(
    date: json['date'] as String,
    score: (json['score'] as num).toDouble(),
  );
}
