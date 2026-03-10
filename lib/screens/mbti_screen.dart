import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../services/gpt_service.dart';
import '../models/mbti_result.dart';

// MBTI 16종
const mbtiTypes = [
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

final mbtiStateProvider = StateNotifierProvider<MbtiNotifier, MbtiState>(
  (ref) => MbtiNotifier(ref.read(gptServiceProvider)),
);

class MbtiState {
  final String? myMbti;
  final String? theirMbti;
  final bool isLoading;
  final MbtiResult? result;
  final String? error;

  const MbtiState({
    this.myMbti,
    this.theirMbti,
    this.isLoading = false,
    this.result,
    this.error,
  });

  MbtiState copyWith({
    String? myMbti,
    String? theirMbti,
    bool? isLoading,
    MbtiResult? result,
    String? error,
  }) => MbtiState(
    myMbti: myMbti ?? this.myMbti,
    theirMbti: theirMbti ?? this.theirMbti,
    isLoading: isLoading ?? this.isLoading,
    result: result ?? this.result,
    error: error ?? this.error,
  );
}

class MbtiNotifier extends StateNotifier<MbtiState> {
  final GptService _gptService;
  MbtiNotifier(this._gptService) : super(const MbtiState());

  void selectMy(String mbti) => state = state.copyWith(myMbti: mbti);
  void selectTheir(String mbti) => state = state.copyWith(theirMbti: mbti);

  Future<void> analyze() async {
    if (state.myMbti == null || state.theirMbti == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _gptService.analyzeMbti(state.myMbti!, state.theirMbti!);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class MbtiScreen extends ConsumerWidget {
  const MbtiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mbtiStateProvider);
    final notifier = ref.read(mbtiStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧬 MBTI 궁합 팩폭'),
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('나의 MBTI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _MbtiGrid(
              selected: state.myMbti,
              onSelect: notifier.selectMy,
              accentColor: const Color(0xFF7B68EE),
            ),

            const SizedBox(height: 20),
            const Text('상대방 MBTI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _MbtiGrid(
              selected: state.theirMbti,
              onSelect: notifier.selectTheir,
              accentColor: const Color(0xFFFF6B9D),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (state.myMbti != null && state.theirMbti != null && !state.isLoading)
                  ? () => notifier.analyze()
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('💥 팩폭 궁합 보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            if (state.result != null) ...[
              const SizedBox(height: 24),
              _MbtiResultCard(result: state.result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _MbtiGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accentColor;

  const _MbtiGrid({required this.selected, required this.onSelect, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: mbtiTypes.length,
      itemBuilder: (context, i) {
        final type = mbtiTypes[i];
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? accentColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MbtiResultCard extends StatelessWidget {
  final MbtiResult result;
  const _MbtiResultCard({required this.result});

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
          Text(
            '${result.myMbti} ❤️ ${result.theirMbti}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          // 궁합 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) => Icon(
                i < (result.compatibilityScore / 20).round() ? Icons.favorite : Icons.favorite_border,
                color: const Color(0xFFFF6B9D),
                size: 28,
              )),
            ],
          ),
          const SizedBox(height: 16),
          // 팩폭 한 줄
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${result.shockLine}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(result.summary, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6)),
          const SizedBox(height: 16),
          // 공유 버튼 (바이럴)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Share.share(
                  '${result.myMbti} ❤️ ${result.theirMbti} 궁합 팩폭\n\n"${result.shockLine}"\n\n솔로의 심쿵감지기로 확인해보세요! 💘',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('인스타/틱톡에 공유하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B68EE),
                side: const BorderSide(color: Color(0xFF7B68EE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
