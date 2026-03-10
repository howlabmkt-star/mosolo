import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../services/gpt_service.dart';
import '../models/analysis_result.dart';

final analysisStateProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>(
  (ref) => AnalysisNotifier(ref.read(gptServiceProvider)),
);

class AnalysisState {
  final bool isLoading;
  final String? filePath;
  final AnalysisResult? freeResult;
  final String? error;

  const AnalysisState({
    this.isLoading = false,
    this.filePath,
    this.freeResult,
    this.error,
  });

  AnalysisState copyWith({
    bool? isLoading,
    String? filePath,
    AnalysisResult? freeResult,
    String? error,
  }) => AnalysisState(
    isLoading: isLoading ?? this.isLoading,
    filePath: filePath ?? this.filePath,
    freeResult: freeResult ?? this.freeResult,
    error: error ?? this.error,
  );
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final GptService _gptService;

  AnalysisNotifier(this._gptService) : super(const AnalysisState());

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      state = state.copyWith(filePath: result.files.single.path);
    }
  }

  Future<void> analyze() async {
    if (state.filePath == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final content = await _readFile(state.filePath!);
      final result = await _gptService.analyzeFree(content);
      state = state.copyWith(isLoading: false, freeResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> _readFile(String path) async {
    // 파일 읽기 (dart:io)
    final file = await _gptService.readTextFile(path);
    return file;
  }
}

class KakaoAnalysisScreen extends ConsumerWidget {
  const KakaoAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisStateProvider);
    final notifier = ref.read(analysisStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 카카오톡 속마음 분석'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📱 카카오톡 대화 내보내기 방법',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('1. 카카오톡 대화방 → 우측 상단 ≡ 메뉴\n'
                    '2. 대화 내용 내보내기 → txt 파일 선택\n'
                    '3. 아래 버튼으로 파일 업로드',
                    style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF555555))),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 파일 업로드 영역
            GestureDetector(
              onTap: () => notifier.pickFile(),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.filePath != null
                      ? const Color(0xFFFF6B9D)
                      : Colors.grey.shade300,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: state.filePath != null
                    ? const Color(0xFFFFF0F5)
                    : Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.filePath != null ? Icons.check_circle : Icons.upload_file,
                      size: 36,
                      color: state.filePath != null
                        ? const Color(0xFFFF6B9D)
                        : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.filePath != null
                        ? state.filePath!.split('/').last
                        : 'txt 파일을 탭하여 업로드',
                      style: TextStyle(
                        color: state.filePath != null
                          ? const Color(0xFFFF6B9D)
                          : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 분석 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.filePath != null && !state.isLoading
                  ? () => notifier.analyze()
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('AI 분석 중... (약 10~20초)'),
                      ],
                    )
                  : const Text('🔍 무료 분석 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            // 에러
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],

            // 무료 결과
            if (state.freeResult != null) ...[
              const SizedBox(height: 24),
              _FreeResultCard(result: state.freeResult!),
              const SizedBox(height: 16),
              _PaywallTeaser(onUpgrade: () => context.push('/paywall')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreeResultCard extends StatelessWidget {
  final AnalysisResult result;
  const _FreeResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('💘 호감도 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // 호감도 점수
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(
                  value: result.score / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    result.score >= 70 ? const Color(0xFFFF6B9D) :
                    result.score >= 40 ? const Color(0xFFFF8E53) : Colors.grey,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${result.score}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                  const Text('/ 100', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 한 줄 요약
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.summary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallTeaser extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _PaywallTeaser({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🔓 990원으로 상세 분석 열기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip('⏱️ 답장 대기시간 분석'),
              _Chip('🔑 핵심 키워드'),
              _Chip('📈 감정 변화 그래프'),
              _Chip('💬 AI 대화 가이드'),
              _Chip('🔮 관계 발전 예측'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF6B9D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('990원으로 풀 분석 보기 →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}
