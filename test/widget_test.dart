import 'package:flutter_test/flutter_test.dart';
import 'package:solo_simkung/models/analysis_result.dart';
import 'package:solo_simkung/models/mbti_result.dart';

void main() {
  group('AnalysisResult', () {
    test('fromJson 정상 파싱', () {
      final json = {
        'score': 75,
        'summary': '호감도가 높습니다',
      };
      final result = AnalysisResult.fromJson(json);
      expect(result.score, 75);
      expect(result.summary, '호감도가 높습니다');
    });

    test('유료 필드 포함 파싱', () {
      final json = {
        'score': 80,
        'summary': '매우 높은 호감도',
        'replyPatterns': [
          {'label': '상대방', 'avgMinutes': 5.0},
          {'label': '나', 'avgMinutes': 10.0},
        ],
        'keywords': [
          {'word': '좋아', 'count': 15, 'sentiment': 'positive'},
        ],
        'emotionChart': [
          {'date': '01/01', 'score': 0.8},
        ],
        'aiGuide': '1. 먼저 연락해보세요',
        'prediction': '관계가 발전할 가능성이 높습니다',
      };
      final result = AnalysisResult.fromJson(json);
      expect(result.replyPatterns?.length, 2);
      expect(result.keywords?.first.word, '좋아');
      expect(result.emotionChart?.first.score, 0.8);
    });
  });

  group('MbtiResult', () {
    test('fromJson 정상 파싱', () {
      final json = {
        'myMbti': 'INFP',
        'theirMbti': 'ENFJ',
        'compatibilityScore': 85,
        'shockLine': '완벽한 천생연분!',
        'summary': '두 유형은 서로를 완성시켜주는 관계입니다.',
      };
      final result = MbtiResult.fromJson(json);
      expect(result.myMbti, 'INFP');
      expect(result.compatibilityScore, 85);
      expect(result.shockLine, '완벽한 천생연분!');
    });
  });
}
