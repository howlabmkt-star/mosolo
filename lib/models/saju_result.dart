class SajuFourPillars {
  final String year;
  final String month;
  final String day;
  final String hour;
  final String summary;

  const SajuFourPillars({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.summary,
  });

  factory SajuFourPillars.fromJson(Map<String, dynamic> json) => SajuFourPillars(
    year: json['year'] as String? ?? '',
    month: json['month'] as String? ?? '',
    day: json['day'] as String? ?? '',
    hour: json['hour'] as String? ?? '미입력',
    summary: json['summary'] as String? ?? '',
  );
}

class SajuFiveElements {
  final String dominant;
  final String lacking;
  final String description;

  const SajuFiveElements({
    required this.dominant,
    required this.lacking,
    required this.description,
  });

  factory SajuFiveElements.fromJson(Map<String, dynamic> json) => SajuFiveElements(
    dominant: json['dominant'] as String? ?? '',
    lacking: json['lacking'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

class SajuResult {
  final SajuFourPillars fourPillars;
  final SajuFiveElements fiveElements;
  final String daymaster;
  final String lovePersonality;
  final String idealPartner;
  final String loveIn2025;
  final String shockLine;
  final String advice;

  const SajuResult({
    required this.fourPillars,
    required this.fiveElements,
    required this.daymaster,
    required this.lovePersonality,
    required this.idealPartner,
    required this.loveIn2025,
    required this.shockLine,
    required this.advice,
  });

  factory SajuResult.fromJson(Map<String, dynamic> json) => SajuResult(
    fourPillars: SajuFourPillars.fromJson(json['fourPillars'] as Map<String, dynamic>? ?? {}),
    fiveElements: SajuFiveElements.fromJson(json['fiveElements'] as Map<String, dynamic>? ?? {}),
    daymaster: json['daymaster'] as String? ?? '',
    lovePersonality: json['lovePersonality'] as String? ?? '',
    idealPartner: json['idealPartner'] as String? ?? '',
    loveIn2025: json['loveIn2025'] as String? ?? '',
    shockLine: json['shockLine'] as String? ?? '',
    advice: json['advice'] as String? ?? '',
  );
}
