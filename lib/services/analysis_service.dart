import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_result.dart';
import '../models/mbti_result.dart';

final analysisServiceProvider = Provider<AnalysisService>((ref) => AnalysisService());

class AnalysisService {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  // 파일 경로 대신 텍스트 내용을 직접 전달 (웹/모바일 모두 호환)
  Future<AnalysisResult> analyzeFree(String chatContent) async {
    final callable = _functions.httpsCallable('analyzeFree');
    final result = await callable.call({'chatContent': chatContent});
    return AnalysisResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<AnalysisResult> analyzePremium(String chatContent) async {
    final callable = _functions.httpsCallable(
      'analyzePremium',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({'chatContent': chatContent});
    return AnalysisResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<MbtiResult> analyzeMbti(String myMbti, String theirMbti) async {
    final callable = _functions.httpsCallable('analyzeMbti');
    final result = await callable.call({'myMbti': myMbti, 'theirMbti': theirMbti});
    return MbtiResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }
}
