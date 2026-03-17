import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analysis_service.dart';
import '../services/credit_service.dart';
import '../models/mbti_result.dart';

// MBTI 16종
const mbtiTypes = [
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

// ── 모드 ─────────────────────────────────────────────────────────────────────

enum MbtiMode { mbtiOnly, mbtiSaju }

// ── 상태 ─────────────────────────────────────────────────────────────────────

class MbtiState {
  final MbtiMode mode;
  final String? myMbti;
  final String? theirMbti;
  final DateTime? myBirthDate;
  final DateTime? theirBirthDate;
  final int? myBirthHour;
  final int? theirBirthHour;
  final bool isLoading;
  final MbtiResult? result;
  final String? error;

  const MbtiState({
    this.mode = MbtiMode.mbtiOnly,
    this.myMbti,
    this.theirMbti,
    this.myBirthDate,
    this.theirBirthDate,
    this.myBirthHour,
    this.theirBirthHour,
    this.isLoading = false,
    this.result,
    this.error,
  });

  bool get canAnalyze {
    if (myMbti == null || theirMbti == null) return false;
    if (mode == MbtiMode.mbtiSaju) return myBirthDate != null && theirBirthDate != null;
    return true;
  }

  MbtiState copyWith({
    MbtiMode? mode,
    String? myMbti,
    String? theirMbti,
    DateTime? myBirthDate,
    DateTime? theirBirthDate,
    int? myBirthHour,
    int? theirBirthHour,
    bool? isLoading,
    MbtiResult? result,
    String? error,
    bool clearResult = false,
  }) => MbtiState(
    mode: mode ?? this.mode,
    myMbti: myMbti ?? this.myMbti,
    theirMbti: theirMbti ?? this.theirMbti,
    myBirthDate: myBirthDate ?? this.myBirthDate,
    theirBirthDate: theirBirthDate ?? this.theirBirthDate,
    myBirthHour: myBirthHour ?? this.myBirthHour,
    theirBirthHour: theirBirthHour ?? this.theirBirthHour,
    isLoading: isLoading ?? this.isLoading,
    result: clearResult ? null : (result ?? this.result),
    error: error,
  );
}

// ── 노티파이어 ─────────────────────────────────────────────────────────────────

class MbtiNotifier extends StateNotifier<MbtiState> {
  final AnalysisService _service;
  final CreditService _creditService;

  MbtiNotifier(this._service, this._creditService) : super(const MbtiState());

  void setMode(MbtiMode mode) => state = state.copyWith(mode: mode, clearResult: true);
  void selectMy(String mbti) => state = state.copyWith(myMbti: mbti, clearResult: true);
  void selectTheir(String mbti) => state = state.copyWith(theirMbti: mbti, clearResult: true);
  void setMyBirthDate(DateTime d) => state = state.copyWith(myBirthDate: d);
  void setTheirBirthDate(DateTime d) => state = state.copyWith(theirBirthDate: d);
  void setMyBirthHour(int? h) => state = state.copyWith(myBirthHour: h);
  void setTheirBirthHour(int? h) => state = state.copyWith(theirBirthHour: h);

  Future<void> analyze() async {
    if (!state.canAnalyze) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      MbtiResult result;
      if (state.mode == MbtiMode.mbtiSaju) {
        final hasCredit = await _creditService.hasCredits();
        if (!hasCredit) {
          state = state.copyWith(isLoading: false, error: 'credit_required');
          return;
        }
        final fmt = (DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        result = await _service.analyzeMbtiSaju(
          myMbti: state.myMbti!,
          theirMbti: state.theirMbti!,
          myBirthDate: fmt(state.myBirthDate!),
          theirBirthDate: fmt(state.theirBirthDate!),
          myBirthHour: state.myBirthHour,
          theirBirthHour: state.theirBirthHour,
        );
      } else {
        result = await _service.analyzeMbti(state.myMbti!, state.theirMbti!);
      }
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.');
    }
  }
}

final mbtiStateProvider = StateNotifierProvider.autoDispose<MbtiNotifier, MbtiState>(
  (ref) => MbtiNotifier(ref.read(analysisServiceProvider), ref.read(creditServiceProvider)),
);

// ── 화면 ─────────────────────────────────────────────────────────────────────

class MbtiScreen extends ConsumerWidget {
  const MbtiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mbtiStateProvider);
    final notifier = ref.read(mbtiStateProvider.notifier);
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

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
            _ModeSelector(selected: state.mode, credits: credits, onSelect: notifier.setMode),
            const SizedBox(height: 20),
            const Text('나의 MBTI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _MbtiGrid(selected: state.myMbti, onSelect: notifier.selectMy, accentColor: const Color(0xFF7B68EE)),
            const SizedBox(height: 20),
            const Text('상대방 MBTI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _MbtiGrid(selected: state.theirMbti, onSelect: notifier.selectTheir, accentColor: const Color(0xFFFF6B9D)),
            if (state.mode == MbtiMode.mbtiSaju) ...[
              const SizedBox(height: 24),
              _BirthDateSection(
                label: '나의 생년월일',
                date: state.myBirthDate,
                hour: state.myBirthHour,
                accentColor: const Color(0xFF7B68EE),
                onDatePick: notifier.setMyBirthDate,
                onHourChange: notifier.setMyBirthHour,
              ),
              const SizedBox(height: 12),
              _BirthDateSection(
                label: '상대방 생년월일',
                date: state.theirBirthDate,
                hour: state.theirBirthHour,
                accentColor: const Color(0xFFFF6B9D),
                onDatePick: notifier.setTheirBirthDate,
                onHourChange: notifier.setTheirBirthHour,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: (state.canAnalyze && !state.isLoading) ? () => notifier.analyze() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.mode == MbtiMode.mbtiSaju ? const Color(0xFFFF6B9D) : const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 10), Text('분석 중... (20~30초)'),
                    ])
                  : Text(
                      state.mode == MbtiMode.mbtiSaju
                        ? '🔮 사주+MBTI 합산 팩폭 보기 (1크레딧)'
                        : '💥 MBTI 팩폭 궁합 보기 (무료)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
              ),
            ),
            if (state.error == 'credit_required') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  const Text('💳', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('크레딧이 필요합니다', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () => context.push('/paywall'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, foregroundColor: const Color(0xFFFF6B9D)),
                        child: const Text('990원으로 크레딧 충전 →'),
                      ),
                    ],
                  )),
                ]),
              ),
            ] else if (state.error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(state.error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
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

// ── 모드 선택 ─────────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final MbtiMode selected;
  final int credits;
  final ValueChanged<MbtiMode> onSelect;

  const _ModeSelector({required this.selected, required this.credits, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _ModeCard(
      selected: selected == MbtiMode.mbtiOnly, label: '① MBTI 궁합',
      sublabel: '무료', emoji: '🧬', accentColor: const Color(0xFF7B68EE),
      onTap: () => onSelect(MbtiMode.mbtiOnly),
    )),
    const SizedBox(width: 10),
    Expanded(child: _ModeCard(
      selected: selected == MbtiMode.mbtiSaju, label: '② MBTI+사주',
      sublabel: '990원 (1크레딧)', emoji: '🔮', accentColor: const Color(0xFFFF6B9D),
      onTap: () => onSelect(MbtiMode.mbtiSaju),
      badge: credits > 0 ? '크레딧 ${credits}개 보유' : null,
    )),
  ]);
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final String label, sublabel, emoji;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badge;

  const _ModeCard({required this.selected, required this.label, required this.sublabel,
    required this.emoji, required this.accentColor, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? accentColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? accentColor : Colors.grey.shade300, width: selected ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? accentColor : Colors.grey.shade700)),
        Text(sublabel, style: TextStyle(fontSize: 11, color: selected ? accentColor : Colors.grey)),
        if (badge != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(badge!, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    ),
  );
}

// ── 생년월일 입력 ─────────────────────────────────────────────────────────────

class _BirthDateSection extends StatelessWidget {
  final String label;
  final DateTime? date;
  final int? hour;
  final Color accentColor;
  final ValueChanged<DateTime> onDatePick;
  final ValueChanged<int?> onHourChange;

  const _BirthDateSection({required this.label, required this.date, required this.hour,
    required this.accentColor, required this.onDatePick, required this.onHourChange});

  @override
  Widget build(BuildContext context) {
    final dateText = date == null ? '생년월일 선택' : '${date!.year}년 ${date!.month}월 ${date!.day}일';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date ?? DateTime(1995, 1, 1),
                  firstDate: DateTime(1950), lastDate: DateTime(2010),
                  helpText: label,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: accentColor)),
                    child: child!,
                  ),
                );
                if (picked != null) onDatePick(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: date != null ? accentColor.withOpacity(0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: date != null ? accentColor : Colors.grey.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: date != null ? accentColor : Colors.grey),
                  const SizedBox(width: 8),
                  Text(dateText, style: TextStyle(
                    fontSize: 13, color: date != null ? accentColor : Colors.grey,
                    fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                  )),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: DropdownButtonFormField<int?>(
              value: hour,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                hintText: '시간', hintStyle: const TextStyle(fontSize: 12), isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('모름', style: TextStyle(fontSize: 12))),
                ...List.generate(24, (h) => DropdownMenuItem(value: h, child: Text('$h시', style: const TextStyle(fontSize: 12)))),
              ],
              onChanged: onHourChange,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── MBTI 그리드 ───────────────────────────────────────────────────────────────

class _MbtiGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accentColor;

  const _MbtiGrid({required this.selected, required this.onSelect, required this.accentColor});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4, childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8,
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
            border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.grey.shade700)),
        ),
      );
    },
  );
}

// ── 결과 카드 ─────────────────────────────────────────────────────────────────

class _MbtiResultCard extends StatelessWidget {
  final MbtiResult result;
  const _MbtiResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더 그라데이션
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B68EE), Color(0xFFFF6B9D)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(children: [
            Text('${result.myMbti} 💘 ${result.theirMbti}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            if (result.compatibilityTag.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(result.compatibilityTag,
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
            if (result.isSajuMode)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('MBTI + 사주팔자 합산 궁합', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 점수
            Center(child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    i < (result.compatibilityScore / 20).round() ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFFF6B9D), size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 6),
              Text('${result.compatibilityScore}점',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF7B68EE))),
            ])),
            const SizedBox(height: 18),

            // 팩폭 한 줄
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7B68EE).withOpacity(0.3)),
              ),
              child: Text('"${result.shockLine}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, height: 1.5, color: Color(0xFF4A3F8F)),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),

            // 5영역 레이더 차트
            if (result.radarData != null) ...[
              _SectionTitle(emoji: '📊', title: '5영역 궁합 분석'),
              const SizedBox(height: 12),
              _RadarSection(radarData: result.radarData!),
              const SizedBox(height: 20),
            ],

            // 관계 스토리 (요약)
            _SectionTitle(emoji: '💌', title: '관계 스토리'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.25)),
              ),
              child: Text(result.summary,
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.7)),
            ),
            const SizedBox(height: 22),

            // 심쿵 포인트
            if (result.heartPounds.isNotEmpty) ...[
              _SectionTitle(emoji: '💓', title: '이 조합만의 심쿵 포인트'),
              const SizedBox(height: 10),
              ...result.heartPounds.map((p) => _BulletItem(text: p, color: const Color(0xFFFF6B9D))),
              const SizedBox(height: 20),
            ],

            // 나의 MBTI 특성
            if (result.myPersonality.isNotEmpty) ...[
              _PersonalityBox(
                label: '나 (${result.myMbti}) 연애 특성',
                text: result.myPersonality,
                color: const Color(0xFF7B68EE),
              ),
              const SizedBox(height: 10),
            ],

            // 상대방 MBTI 특성
            if (result.theirPersonality.isNotEmpty) ...[
              _PersonalityBox(
                label: '상대방 (${result.theirMbti}) 연애 특성',
                text: result.theirPersonality,
                color: const Color(0xFFFF6B9D),
              ),
              const SizedBox(height: 20),
            ],

            // 주의할 점
            if (result.dangerZones.isNotEmpty) ...[
              _SectionTitle(emoji: '⚠️', title: '이 커플의 갈등 패턴'),
              const SizedBox(height: 10),
              ...result.dangerZones.map((p) => _BulletItem(text: p, color: Colors.orange.shade700)),
              const SizedBox(height: 20),
            ],

            // 대화 팁
            if (result.talkTips.isNotEmpty) ...[
              _SectionTitle(emoji: '💬', title: '효과적인 대화법'),
              const SizedBox(height: 10),
              ...result.talkTips.map((p) => _BulletItem(text: p, color: const Color(0xFF43A047))),
              const SizedBox(height: 20),
            ],

            // 연애 예측
            if (result.lovePrediction.isNotEmpty) ...[
              _SectionTitle(emoji: '🔮', title: '이 커플의 미래는?'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(result.lovePrediction,
                  style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF555555))),
              ),
              const SizedBox(height: 20),
            ],

            // ── 스킨십 단계 추천 (사주 유료 전용) ─────────────────────────
            if (result.isSajuMode && result.recommendedSkinshipStage != null) ...[
              _SectionTitle(emoji: '💑', title: '스킨십 단계 가이드'),
              const SizedBox(height: 12),
              _SkinshipGuide(
                recommendedStage: result.recommendedSkinshipStage!,
                advice: result.skinshipAdvice ?? '',
              ),
              const SizedBox(height: 20),
            ],

            // ── MBTI 데이트 코스 (사주 유료 전용) ────────────────────────
            if (result.isSajuMode && result.datingCourse != null && result.datingCourse!.isNotEmpty) ...[
              _SectionTitle(emoji: '🗺️', title: 'MBTI 맞춤 데이트 코스'),
              const SizedBox(height: 10),
              ...result.datingCourse!.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7B68EE).withOpacity(0.25)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Color(0xFF7B68EE), shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333)))),
                ]),
              )),
              const SizedBox(height: 20),
            ],

            // ── 갈등 해결법 (사주 유료 전용) ─────────────────────────────
            if (result.isSajuMode && result.conflictResolution != null) ...[
              _SectionTitle(emoji: '🤝', title: '이 커플의 갈등 해결 비법'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
                ),
                child: Text(result.conflictResolution!,
                  style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF2E4F34))),
              ),
              const SizedBox(height: 20),
            ],

            // 사주 2단계 전용 섹션
            if (result.isSajuMode) ...[
              // 천생연분 점수
              if (result.destinyScore != null) ...[
                _SectionTitle(emoji: '⭐', title: '천생연분 점수'),
                const SizedBox(height: 12),
                _DestinyScoreBar(score: result.destinyScore!),
                const SizedBox(height: 20),
              ],

              // 오행 궁합 분석
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('🀄', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text('오행 궁합 분석', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 12),
                  if (result.myPillar != null) _PillarRow('나', result.myPillar!),
                  if (result.theirPillar != null) _PillarRow('상대방', result.theirPillar!),
                  const SizedBox(height: 10),
                  Text(result.sajuAnalysis!, style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444))),
                ]),
              ),
              const SizedBox(height: 16),

              // 전생 스토리
              if (result.pastLifeStory != null) ...[
                _SectionTitle(emoji: '🌙', title: '전생 인연 스토리'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6A0DAD).withOpacity(0.25)),
                  ),
                  child: Text(result.pastLifeStory!,
                    style: const TextStyle(fontSize: 13, height: 1.8, color: Color(0xFF3D0066), fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 16),
              ],

              // 최고의 달 / 위기의 달
              if (result.bestMonth != null || result.crisisMonth != null) ...[
                _SectionTitle(emoji: '📅', title: '이 커플의 달력'),
                const SizedBox(height: 10),
                Row(children: [
                  if (result.bestMonth != null)
                    Expanded(child: _MonthCard(
                      emoji: '🌸',
                      title: '최고의 달',
                      content: result.bestMonth!,
                      color: const Color(0xFF43A047),
                    )),
                  if (result.bestMonth != null && result.crisisMonth != null)
                    const SizedBox(width: 10),
                  if (result.crisisMonth != null)
                    Expanded(child: _MonthCard(
                      emoji: '⚡',
                      title: '위기의 달',
                      content: result.crisisMonth!,
                      color: Colors.deepOrange,
                    )),
                ]),
                const SizedBox(height: 16),
              ],

              // 종합 판정
              if (result.overallVerdict != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFF7B68EE)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('⚖️ 종합 판정: ${result.overallVerdict!}',
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700, height: 1.5),
                    textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 18),
            ],

            // 공유 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final sajuPart = result.isSajuMode ? '\n🀄 사주+MBTI 합산 분석' : '';
                  final heartPart = result.heartPounds.isNotEmpty
                    ? '\n\n💓 심쿵 포인트\n${result.heartPounds.map((e) => '• $e').join('\n')}'
                    : '';
                  Share.share(
                    '${result.myMbti} 💘 ${result.theirMbti} 궁합$sajuPart\n'
                    '${result.compatibilityTag.isNotEmpty ? "[${result.compatibilityTag}]" : ""}\n\n'
                    '"${result.shockLine}"\n\n'
                    '${result.summary}'
                    '$heartPart\n\n'
                    '솔로의 심쿵감지기에서 확인해보세요! 💘\nhttps://solo-simkung.web.app',
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('인스타/틱톡에 캡처 공유하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── 공용 위젯 ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String emoji, title;
  const _SectionTitle({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF333333))),
  ]);
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444)))),
    ]),
  );
}

class _PersonalityBox extends StatelessWidget {
  final String label, text;
  final Color color;
  const _PersonalityBox({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 6),
      Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444))),
    ]),
  );
}

class _PillarRow extends StatelessWidget {
  final String label;
  final String value;
  const _PillarRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 52, child: Text('$label:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF856404)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF555555)))),
    ]),
  );
}

// ── 레이더 차트 ───────────────────────────────────────────────────────────────

class _RadarSection extends StatelessWidget {
  final Map<String, double> radarData;
  const _RadarSection({required this.radarData});

  @override
  Widget build(BuildContext context) {
    final labels = ['소통력', '설렘지수', '안정감', '성장가능성', '위기관리'];
    final keys   = ['communication', 'excitement', 'stability', 'growth', 'crisis'];
    final values = keys.map((k) => (radarData[k] ?? 50.0)).toList();

    return SizedBox(
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        RadarChart(
          RadarChartData(
            dataSets: [
              RadarDataSet(
                dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                fillColor: const Color(0xFF7B68EE).withOpacity(0.25),
                borderColor: const Color(0xFF7B68EE),
                borderWidth: 2,
                entryRadius: 4,
              ),
            ],
            radarShape: RadarShape.polygon,
            radarBorderData: const BorderSide(color: Colors.transparent),
            tickBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
            gridBorderData: BorderSide(color: Colors.grey.shade200, width: 1),
            tickCount: 4,
            ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
            titleTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            titlePositionPercentageOffset: 0.18,
            getTitle: (index, angle) {
              final val = values[index].toInt();
              return RadarChartTitle(text: '${labels[index]}\n$val', angle: 0);
            },
            radarBackgroundColor: Colors.transparent,
          ),
        ),
      ]),
    );
  }
}

// ── 천생연분 점수 바 ──────────────────────────────────────────────────────────

class _DestinyScoreBar extends StatelessWidget {
  final int score;
  const _DestinyScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? const Color(0xFFFF6B9D)
      : score >= 60 ? const Color(0xFFFF8E53) : Colors.grey;
    final label = score >= 80 ? '전생부터 이어진 인연' : score >= 60 ? '이번 생에서 이어진 인연' : '우연히 만난 인연';
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        Text('$score점', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 12,
        ),
      ),
    ]);
  }
}

// ── 스킨십 단계 가이드 ────────────────────────────────────────────────────────

const _skinshipData = [
  {'emoji': '👀', 'title': '눈 맞춤 & 미소', 'desc': '자연스러운 시선 교환'},
  {'emoji': '🤝', 'title': '가벼운 신체 접촉', 'desc': '팔 스치기, 어깨 터치'},
  {'emoji': '🤲', 'title': '손잡기', 'desc': '두근두근 첫 손 잡기'},
  {'emoji': '💪', 'title': '팔짱 & 어깨 동무', 'desc': '친밀감 UP'},
  {'emoji': '🤗', 'title': '포옹', 'desc': '따뜻한 감정 나누기'},
  {'emoji': '😘', 'title': '볼 뽀뽀 & 이마 키스', 'desc': '애정 표현의 시작'},
  {'emoji': '💋', 'title': '첫 키스', 'desc': '관계의 전환점'},
];

class _SkinshipGuide extends StatelessWidget {
  final int recommendedStage;  // 1~7
  final String advice;
  const _SkinshipGuide({required this.recommendedStage, required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 단계 표시
        Row(
          children: List.generate(_skinshipData.length, (i) {
            final isRecommended = i + 1 == recommendedStage;
            final isPassed = i + 1 < recommendedStage;
            return Expanded(
              child: Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isRecommended
                      ? const Color(0xFFFF6B9D)
                      : isPassed
                        ? const Color(0xFFFF6B9D).withOpacity(0.3)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: isRecommended ? [
                      BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
                    ] : [],
                  ),
                  child: Center(
                    child: Text(
                      _skinshipData[i]['emoji'] as String,
                      style: TextStyle(fontSize: isRecommended ? 16 : 13),
                    ),
                  ),
                ),
                if (i < _skinshipData.length - 1)
                  Container(
                    height: 2,
                    color: isPassed ? const Color(0xFFFF6B9D).withOpacity(0.4) : Colors.grey.shade200,
                  ),
              ]),
            );
          }),
        ),
        const SizedBox(height: 14),

        // 추천 단계 상세
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                _skinshipData[recommendedStage - 1]['emoji'] as String,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${recommendedStage}단계 추천',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B9D), fontWeight: FontWeight.w600),
                ),
                Text(
                  _skinshipData[recommendedStage - 1]['title'] as String,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF333333)),
                ),
              ]),
            ]),
            if (advice.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(advice, style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF555555))),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── 최고/위기의 달 카드 ───────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final String emoji, title, content;
  final Color color;
  const _MonthCard({required this.emoji, required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 6),
      Text(content, style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF444444))),
    ]),
  );
}
