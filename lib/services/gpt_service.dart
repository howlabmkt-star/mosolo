import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../models/mbti_result.dart';

final gptServiceProvider = Provider<GptService>((ref) => GptService());

class GptService {
  // TODO: 환경변수 또는 Firebase Remote Config로 관리
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  Future<String> readTextFile(String path) async {
    final file = File(path);
    // 원문은 메모리에서만 처리 (저장 안 함)
    return await file.readAsString();
  }

  /// 무료 분석: 호감도 점수 + 한 줄 요약만 반환
  Future<AnalysisResult> analyzeFree(String chatContent) async {
    // 토큰 절약을 위해 최근 200줄만 사용
    final lines = chatContent.split('\n');
    final trimmed = lines.length > 200
      ? lines.sublist(lines.length - 200).join('\n')
      : chatContent;

    final response = await _callGpt(
      systemPrompt: '''당신은 연애 심리 전문가입니다. 카카오톡 대화를 분석해 상대방의 호감도를 측정합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "score": <0~100 정수>,
  "summary": "<20자 이내 한 줄 요약>"
}''',
      userPrompt: '다음 카카오톡 대화를 분석해주세요:\n\n$trimmed',
    );

    final json = jsonDecode(response) as Map<String, dynamic>;
    return AnalysisResult.fromJson(json);
  }

  /// 유료 분석: 전체 상세 분석
  Future<AnalysisResult> analyzePremium(String chatContent) async {
    final response = await _callGpt(
      systemPrompt: '''당신은 연애 심리 전문가입니다. 카카오톡 대화를 심층 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "score": <0~100 정수>,
  "summary": "<한 줄 요약>",
  "replyPatterns": [{"label": "상대방", "avgMinutes": <평균 답장시간(분)>}, {"label": "나", "avgMinutes": <평균 답장시간(분)>}],
  "keywords": [{"word": "<키워드>", "count": <횟수>, "sentiment": "positive|negative|neutral"}],
  "emotionChart": [{"date": "<날짜>", "score": <0.0~1.0>}],
  "aiGuide": "<다음 대화 가이드 3줄>",
  "prediction": "<관계 발전 예측 2줄>"
}''',
      userPrompt: '다음 카카오톡 대화를 심층 분석해주세요:\n\n$chatContent',
    );

    final json = jsonDecode(response) as Map<String, dynamic>;
    return AnalysisResult.fromJson(json);
  }

  /// MBTI 궁합 분석 (동일 조합 캐싱 가능)
  Future<MbtiResult> analyzeMbti(String myMbti, String theirMbti) async {
    final response = await _callGpt(
      systemPrompt: '''당신은 MBTI 전문가입니다. 두 MBTI의 연애 궁합을 팩폭 스타일로 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "myMbti": "$myMbti",
  "theirMbti": "$theirMbti",
  "compatibilityScore": <0~100 정수>,
  "shockLine": "<충격적이고 재미있는 한 줄 팩폭, SNS 공유 유도>",
  "summary": "<궁합 요약 3~4문장>"
}''',
      userPrompt: '$myMbti와 $theirMbti의 연애 궁합을 분석해주세요.',
    );

    final json = jsonDecode(response) as Map<String, dynamic>;
    return MbtiResult.fromJson(json);
  }

  Future<String> _callGpt({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final resp = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('GPT API 오류: ${resp.statusCode} ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['choices'] as List).first['message']['content'] as String;
  }
}
