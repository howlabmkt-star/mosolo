import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_result.dart';
import '../models/mbti_result.dart';

final analysisServiceProvider = Provider<AnalysisService>((ref) => AnalysisService());

class AnalysisService {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  Future<AnalysisResult> analyzeFree(String filePath) async {
    final content = await File(filePath).readAsString();

    final callable = _functions.httpsCallable('analyzeFree');
    final result = await callable.call({'chatContent': content});

    return AnalysisResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<AnalysisResult> analyzePremium(String filePath) async {
    final content = await File(filePath).readAsString();

    final callable = _functions.httpsCallable(
      'analyzePremium',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({'chatContent': content});

    return AnalysisResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }

  Future<MbtiResult> analyzeMbti(String myMbti, String theirMbti) async {
    final callable = _functions.httpsCallable('analyzeMbti');
    final result = await callable.call({'myMbti': myMbti, 'theirMbti': theirMbti});

    return MbtiResult.fromJson(Map<String, dynamic>.from(result.data as Map));
  }
}
