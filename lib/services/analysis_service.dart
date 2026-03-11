import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_result.dart';
import '../models/mbti_result.dart';
import '../models/saju_result.dart';
import '../models/relationship_result.dart';

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
    final callable = _functions.httpsCallable(
      'analyzeMbti',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
    );
    final result = await callable.call({'myMbti': myMbti, 'theirMbti': theirMbti});
    return MbtiResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<MbtiResult> analyzeMbtiSaju({
    required String myMbti,
    required String theirMbti,
    required String myBirthDate,
    required String theirBirthDate,
    int? myBirthHour,
    int? theirBirthHour,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeMbtiSaju',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({
      'myMbti': myMbti,
      'theirMbti': theirMbti,
      'myBirthDate': myBirthDate,
      'theirBirthDate': theirBirthDate,
      if (myBirthHour != null) 'myBirthHour': myBirthHour,
      if (theirBirthHour != null) 'theirBirthHour': theirBirthHour,
    });
    return MbtiResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<SajuResult> analyzeSaju({
    required String birthDate,
    int? birthHour,
    required String gender,
    String? question,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeSaju',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({
      'birthDate': birthDate,
      'gender': gender,
      if (birthHour != null) 'birthHour': birthHour,
      if (question != null && question.isNotEmpty) 'question': question,
    });
    return SajuResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<RelationshipResult> analyzeRelationship(String behaviorText) async {
    final callable = _functions.httpsCallable(
      'analyzeRelationship',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call({'behaviorText': behaviorText});
    return RelationshipResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<RelationshipResult> analyzeRelationshipSaju({
    required String behaviorText,
    required String myBirthDate,
    required String theirBirthDate,
    int? myBirthHour,
    int? theirBirthHour,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeRelationshipSaju',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({
      'behaviorText': behaviorText,
      'myBirthDate': myBirthDate,
      'theirBirthDate': theirBirthDate,
      if (myBirthHour != null) 'myBirthHour': myBirthHour,
      if (theirBirthHour != null) 'theirBirthHour': theirBirthHour,
    });
    return RelationshipResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }
}
