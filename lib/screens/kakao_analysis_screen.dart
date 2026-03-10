import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis_result.dart';
import '../services/analysis_service.dart';
import '../services/credit_service.dart';
import 'premium_result_screen.dart';

// ── 상태 ────────────────────────────────────────────────────────────────────

class _KakaoState {
  final bool isLoading;
  final bool isPremiumLoading;
  final String? fileName;     // 표시용 파일명
  final String? fileContent;  // 실제 텍스트 내용 (웹/모바일 공통)
  final AnalysisResult? freeResult;
  final String? error;

  const _KakaoState({
    this.isLoading = false,
    this.isPremiumLoading = false,
    this.fileName,
    this.fileContent,
    this.freeResult,
    this.error,
  });

  _KakaoState copyWith({
    bool? isLoading,
    bool? isPremiumLoading,
    String? fileName,
    String? fileContent,
    AnalysisResult? freeResult,
    String? error,
  }) => _KakaoState(
    isLoading: isLoading ?? this.isLoading,
    isPremiumLoading: isPremiumLoading ?? this.isPremiumLoading,
    fileName: fileName ?? this.fileName,
    fileContent: fileContent ?? this.fileContent,
    freeResult: freeResult ?? this.freeResult,
    error: error ?? this.error,
  );
}

class _KakaoNotifier extends StateNotifier<_KakaoState> {
  final AnalysisService _service;
  final CreditService _creditService;

  _KakaoNotifier(this._service, this._creditService) : super(const _KakaoState());

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: kIsWeb, // 웹에서는 bytes로 직접 읽기
    );
    if (result == null) return;

    final file = result.files.single;
    String? content;

    if (kIsWeb && file.bytes != null) {
      // 웹: bytes → UTF-8 문자열 변환
      content = utf8.decode(file.bytes!);
    } else if (!kIsWeb && file.path != null) {
      // 모바일/데스크톱: 파일 경로로 읽기
      content = await File(file.path!).readAsString();
    }

    if (content != null) {
      state = state.copyWith(
        fileName: file.name,
        fileContent: content,
        freeResult: null,
        error: null,
      );
    }
  }

  Future<void> analyzeFree() async {
    if (state.fileContent == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.analyzeFree(state.fileContent!);
      state = state.copyWith(isLoading: false, freeResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    }
  }

  Future<AnalysisResult?> analyzePremium() async {
    if (state.fileContent == null) return null;
    final hasCredit = await _creditService.hasCredits();
    if (!hasCredit) return null;

    state = state.copyWith(isPremiumLoading: true, error: null);
    try {
      final result = await _service.analyzePremium(state.fileContent!);
      state = state.copyWith(isPremiumLoading: false);
      return result;
    } catch (e) {
      final msg = e.toString().contains('resource-exhausted')
        ? '크레딧이 부족합니다. 충전 후 이용해주세요.'
        : '분석 중 오류가 발생했습니다.';
      state = state.copyWith(isPremiumLoading: false, error: msg);
      return null;
    }
  }
}

final _kakaoProvider = StateNotifierProvider.autoDispose<_KakaoNotifier, _KakaoState>(
  (ref) => _KakaoNotifier(
    ref.read(analysisServiceProvider),
    ref.read(creditServiceProvider),
  ),
);

// ── 화면 ────────────────────────────────────────────────────────────────────

class KakaoAnalysisScreen extends ConsumerWidget {
  const KakaoAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_kakaoProvider);
    final notifier = ref.read(_kakaoProvider.notifier);
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 카카오톡 속마음 분석'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('$credits 크레딧', style: const TextStyle(fontSize: 12)),
              avatar: const Text('💳', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.white.withOpacity(0.2),
              side: BorderSide.none,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideCard(),
            const SizedBox(height: 20),
            _FileUploadArea(fileName: state.fileName, onTap: () => notifier.pickFile()),
            const SizedBox(height: 14),
            _AnalyzeButton(
              enabled: state.fileContent != null && !state.isLoading,
              isLoading: state.isLoading,
              onTap: () => notifier.analyzeFree(),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              _ErrorBox(message: state.error!),
            ],
            if (state.freeResult != null) ...[
              const SizedBox(height: 24),
              _FreeResultCard(result: state.freeResult!),
              const SizedBox(height: 16),
              _PaywallCta(
                isLoading: state.isPremiumLoading,
                hasCredits: credits > 0,
                onUpgrade: () async {
                  if (credits <= 0) {
                    context.push('/paywall');
                    return;
                  }
                  final result = await notifier.analyzePremium();
                  if (result != null && context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PremiumResultScreen(result: result),
                    ));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📱 카카오톡 내보내기 방법', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 8),
          Text(
            '1. 대화방 → 우측 상단 ≡ 메뉴\n'
            '2. 대화 내용 내보내기 → txt 파일 선택\n'
            '3. 아래에 txt 파일 업로드',
            style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }
}

class _FileUploadArea extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _FileUploadArea({required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: hasFile ? const Color(0xFFFF6B9D) : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? const Color(0xFFFFF0F5) : Colors.grey.shade50,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(hasFile ? Icons.check_circle : Icons.upload_file, size: 34,
            color: hasFile ? const Color(0xFFFF6B9D) : Colors.grey),
          const SizedBox(height: 8),
          Text(
            hasFile ? fileName! : 'txt 파일 탭하여 업로드',
            style: TextStyle(color: hasFile ? const Color(0xFFFF6B9D) : Colors.grey, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _AnalyzeButton({required this.enabled, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B9D), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 10),
              Text('AI 분석 중... (10~20초)'),
            ])
          : const Text('🔍 무료 분석 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
    );
  }
}

class _FreeResultCard extends StatelessWidget {
  final AnalysisResult result;
  const _FreeResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.score >= 70 ? const Color(0xFFFF6B9D)
      : result.score >= 40 ? const Color(0xFFFF8E53) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        const Text('💘 무료 호감도 결과', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120,
            child: CircularProgressIndicator(
              value: result.score / 100, strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${result.score}', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: color)),
            const Text('/ 100', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)),
          child: Text(result.summary, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5), textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}

class _PaywallCta extends StatelessWidget {
  final bool isLoading;
  final bool hasCredits;
  final VoidCallback onUpgrade;

  const _PaywallCta({required this.isLoading, required this.hasCredits, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Text(
          hasCredits ? '🔓 크레딧으로 상세 분석 열기' : '🔓 990원으로 상세 분석 열기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 10),
        const Wrap(spacing: 8, runSpacing: 6, children: [
          _Chip('⏱️ 답장 대기시간'), _Chip('🔑 핵심 키워드'),
          _Chip('📈 감정 그래프'), _Chip('💬 AI 가이드'), _Chip('🔮 관계 예측'),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: const Color(0xFFFF6B9D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: isLoading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Color(0xFFFF6B9D), strokeWidth: 2))
              : Text(
                  hasCredits ? '크레딧으로 풀 분석 보기 →' : '990원으로 풀 분석 보기 →',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
  );
}
