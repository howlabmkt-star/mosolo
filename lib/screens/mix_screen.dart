import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analysis_service.dart';
import '../services/credit_service.dart';

// ── 상태 ─────────────────────────────────────────────────────────────────────

const mbtiTypes = [
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

class MixState {
  final String? myMbti;
  final String? theirMbti;
  final DateTime? myBirthDate;
  final DateTime? theirBirthDate;
  final int? myBirthHour;
  final int? theirBirthHour;
  final String? chatContent;
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const MixState({
    this.myMbti,
    this.theirMbti,
    this.myBirthDate,
    this.theirBirthDate,
    this.myBirthHour,
    this.theirBirthHour,
    this.chatContent,
    this.isLoading = false,
    this.result,
    this.error,
  });

  bool get canAnalyze =>
    myMbti != null && theirMbti != null &&
    myBirthDate != null && theirBirthDate != null;

  MixState copyWith({
    String? myMbti,
    String? theirMbti,
    DateTime? myBirthDate,
    DateTime? theirBirthDate,
    int? myBirthHour,
    int? theirBirthHour,
    String? chatContent,
    bool? isLoading,
    Map<String, dynamic>? result,
    String? error,
  }) => MixState(
    myMbti: myMbti ?? this.myMbti,
    theirMbti: theirMbti ?? this.theirMbti,
    myBirthDate: myBirthDate ?? this.myBirthDate,
    theirBirthDate: theirBirthDate ?? this.theirBirthDate,
    myBirthHour: myBirthHour ?? this.myBirthHour,
    theirBirthHour: theirBirthHour ?? this.theirBirthHour,
    chatContent: chatContent ?? this.chatContent,
    isLoading: isLoading ?? this.isLoading,
    result: result ?? this.result,
    error: error,
  );
}

class MixNotifier extends StateNotifier<MixState> {
  final AnalysisService _service;
  final CreditService _creditService;

  MixNotifier(this._service, this._creditService) : super(const MixState());

  void setMyMbti(String v) => state = state.copyWith(myMbti: v);
  void setTheirMbti(String v) => state = state.copyWith(theirMbti: v);
  void setMyDate(DateTime d) => state = state.copyWith(myBirthDate: d);
  void setTheirDate(DateTime d) => state = state.copyWith(theirBirthDate: d);
  void setMyHour(int? h) => state = state.copyWith(myBirthHour: h);
  void setTheirHour(int? h) => state = state.copyWith(theirBirthHour: h);
  void setChatContent(String v) => state = state.copyWith(chatContent: v.isEmpty ? null : v);

  String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> analyze() async {
    if (!state.canAnalyze) return;

    final credits = await _creditService.getCredits();
    if (credits < 2) {
      state = state.copyWith(error: 'credit_required');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.analyzeMix(
        myMbti: state.myMbti!,
        theirMbti: state.theirMbti!,
        myBirthDate: _fmt(state.myBirthDate!),
        theirBirthDate: _fmt(state.theirBirthDate!),
        myBirthHour: state.myBirthHour,
        theirBirthHour: state.theirBirthHour,
        chatContent: state.chatContent,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.');
    }
  }
}

final mixProvider = StateNotifierProvider.autoDispose<MixNotifier, MixState>(
  (ref) => MixNotifier(ref.read(analysisServiceProvider), ref.read(creditServiceProvider)),
);

// ── 화면 ─────────────────────────────────────────────────────────────────────

class MixScreen extends ConsumerWidget {
  const MixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mixProvider);
    final notifier = ref.read(mixProvider.notifier);
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌟 종합 연애 리포트',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('MBTI + 사주 + 카카오톡 믹스 분석\n이 커플만을 위한 맞춤 리포트',
                          style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBF00).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFBF00).withOpacity(0.5)),
                          ),
                          child: Text(
                            '2크레딧 (1,980원) · 현재 $credits크레딧 보유',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFFFBF00), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                if (state.result == null) ...[
                  // MBTI 선택
                  _DarkCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _DarkSectionTitle(emoji: '🧬', title: 'MBTI 선택'),
                      const SizedBox(height: 14),
                      _MbtiRow(
                        label: '나의 MBTI',
                        selected: state.myMbti,
                        accentColor: const Color(0xFF7B68EE),
                        onSelect: notifier.setMyMbti,
                      ),
                      const SizedBox(height: 12),
                      _MbtiRow(
                        label: '상대방 MBTI',
                        selected: state.theirMbti,
                        accentColor: const Color(0xFFFF6B9D),
                        onSelect: notifier.setTheirMbti,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // 생년월일
                  _DarkCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _DarkSectionTitle(emoji: '🔮', title: '생년월일 (사주 계산)'),
                      const SizedBox(height: 14),
                      _DarkBirthRow(
                        label: '나의 생년월일',
                        date: state.myBirthDate,
                        hour: state.myBirthHour,
                        onDatePick: notifier.setMyDate,
                        onHourChange: notifier.setMyHour,
                      ),
                      const SizedBox(height: 10),
                      _DarkBirthRow(
                        label: '상대방 생년월일',
                        date: state.theirBirthDate,
                        hour: state.theirBirthHour,
                        onDatePick: notifier.setTheirDate,
                        onHourChange: notifier.setTheirHour,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // 카카오 (선택)
                  _DarkCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        _DarkSectionTitle(emoji: '💬', title: '카카오톡 대화'),
                        SizedBox(width: 8),
                        Text('(선택사항)', style: TextStyle(fontSize: 11, color: Colors.white38)),
                      ]),
                      const SizedBox(height: 10),
                      TextField(
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        decoration: InputDecoration(
                          hintText: '카카오톡 대화를 붙여넣으면 더 정확해요\n(없어도 분석 가능)',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 1.5),
                          ),
                        ),
                        onChanged: notifier.setChatContent,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // 분석 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (state.canAnalyze && !state.isLoading)
                        ? () => notifier.analyze()
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: state.isLoading
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('AI 분석 중... (30~60초)', style: TextStyle(fontSize: 15)),
                          ])
                        : const Text('🌟 종합 리포트 생성 (2크레딧)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),

                  // 크레딧 부족
                  if (state.error == 'credit_required') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💳 크레딧이 부족합니다 (2개 필요)',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => context.push('/paywall'),
                          child: const Text('충전하러 가기 →',
                            style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ] else if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ],

                // 결과
                if (state.result != null) ...[
                  _MixResultView(result: state.result!),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 다크 UI 공용 위젯 ─────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E35),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: child,
  );
}

class _DarkSectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  const _DarkSectionTitle({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 17)),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70)),
  ]);
}

// ── MBTI 선택 행 ──────────────────────────────────────────────────────────────

class _MbtiRow extends StatelessWidget {
  final String label;
  final String? selected;
  final Color accentColor;
  final ValueChanged<String> onSelect;

  const _MbtiRow({required this.label, required this.selected, required this.accentColor, required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mbtiTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final type = mbtiTypes[i];
          final isSelected = selected == type;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? accentColor : Colors.white.withOpacity(0.12)),
              ),
              alignment: Alignment.center,
              child: Text(type, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white54,
              )),
            ),
          );
        },
      ),
    ),
  ]);
}

// ── 다크 생년월일 입력 행 ─────────────────────────────────────────────────────

class _DarkBirthRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final int? hour;
  final ValueChanged<DateTime> onDatePick;
  final ValueChanged<int?> onHourChange;

  const _DarkBirthRow({required this.label, required this.date, required this.hour,
    required this.onDatePick, required this.onHourChange});

  @override
  Widget build(BuildContext context) {
    final dateText = date == null
      ? '생년월일 선택'
      : '${date!.year}년 ${date!.month}월 ${date!.day}일';

    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime(1998, 1, 1),
              firstDate: DateTime(1950),
              lastDate: DateTime(2010),
              helpText: label,
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B9D)),
                ),
                child: child!,
              ),
            );
            if (picked != null) onDatePick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: date != null ? const Color(0xFFFF6B9D).withOpacity(0.6) : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.white38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 12,
                    color: date != null ? Colors.white : Colors.white38,
                    fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white30)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 76,
        child: DropdownButtonFormField<int?>(
          value: hour,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E35),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            hintText: '시간',
            hintStyle: const TextStyle(fontSize: 11, color: Colors.white30),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('모름', style: TextStyle(fontSize: 11, color: Colors.white54))),
            ...List.generate(24, (h) => DropdownMenuItem(
              value: h,
              child: Text('$h시', style: const TextStyle(fontSize: 11, color: Colors.white)),
            )),
          ],
          onChanged: onHourChange,
        ),
      ),
    ]);
  }
}

// ── 종합 리포트 결과 뷰 ───────────────────────────────────────────────────────

class _MixResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  const _MixResultView({required this.result});

  String _s(String key) => result[key] as String? ?? '';
  int _i(String key) => (result[key] as num?)?.toInt() ?? 0;
  List<String> _l(String key) {
    final v = result[key];
    if (v == null) return [];
    return (v as List).map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final score = _i('overallScore');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // 종합 점수 카드
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFF7B68EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          Text('🌟', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('$score점', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          const SizedBox(height: 6),
          Text(_s('overallTag'), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('"${_s('shockLine')}"',
              style: const TextStyle(fontSize: 15, color: Colors.white, fontStyle: FontStyle.italic, height: 1.4),
              textAlign: TextAlign.center),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // MBTI 시너지
      if (_s('mbtiSynergy').isNotEmpty) ...[
        _DarkResultSection(emoji: '🧬', title: 'MBTI 케미', content: _s('mbtiSynergy')),
        const SizedBox(height: 14),
      ],

      // 사주 시너지
      if (_s('sajuSynergy').isNotEmpty) ...[
        _DarkResultSection(emoji: '🔮', title: '사주 오행 궁합', content: _s('sajuSynergy')),
        const SizedBox(height: 14),
      ],

      // 카카오 인사이트
      if (_s('chatInsight').isNotEmpty) ...[
        _DarkResultSection(emoji: '💬', title: '카카오톡 감정 분석', content: _s('chatInsight')),
        const SizedBox(height: 14),
      ],

      // 강점/약점
      if (_l('strengthPoints').isNotEmpty || _l('weakPoints').isNotEmpty) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_l('strengthPoints').isNotEmpty)
            Expanded(child: _SignalBox(title: '💪 강점', items: _l('strengthPoints'), color: const Color(0xFF43A047))),
          const SizedBox(width: 10),
          if (_l('weakPoints').isNotEmpty)
            Expanded(child: _SignalBox(title: '⚠️ 약점', items: _l('weakPoints'), color: const Color(0xFFFF8E53))),
        ]),
        const SizedBox(height: 14),
      ],

      // 스킨십 추천
      if (_s('skinshipRecommendation').isNotEmpty) ...[
        _DarkCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _DarkSectionTitle(emoji: '💑', title: '스킨십 추천'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Text('💑', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_i("recommendedSkinshipStage")}단계 추천',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFF6B9D)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(_s('skinshipRecommendation'),
              style: const TextStyle(fontSize: 13, height: 1.7, color: Colors.white60)),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // 이달의 운세
      if (_s('monthlyFortune').isNotEmpty) ...[
        _DarkResultSection(emoji: '📅', title: '이달의 연애 운세', content: _s('monthlyFortune')),
        const SizedBox(height: 14),
      ],

      // 행동 계획
      if (_l('actionPlan').isNotEmpty) ...[
        _DarkCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _DarkSectionTitle(emoji: '🎯', title: '지금 바로 해야 할 행동'),
            const SizedBox(height: 12),
            ..._l('actionPlan').asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFF7B68EE)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${e.key + 1}',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.white70))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // 미래 예측
      if (_s('futureVision').isNotEmpty) ...[
        _DarkResultSection(emoji: '🔭', title: '3개월 · 6개월 · 1년 후', content: _s('futureVision')),
        const SizedBox(height: 14),
      ],

      // 이 커플의 무기
      if (_s('secretWeapon').isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFBF00), Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('⚡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 6),
              Text('이 커플만의 무기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
            ]),
            const SizedBox(height: 8),
            Text(_s('secretWeapon'), style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87)),
          ]),
        ),
        const SizedBox(height: 20),
      ],

      // 공유 버튼
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Share.share(
            '🌟 종합 연애 리포트\n\n'
            '${_s("overallTag")} · $_i점\n'
            '"${_s("shockLine")}"\n\n'
            '스킨십 ${_i("recommendedSkinshipStage")}단계 추천\n\n'
            '솔로의 심쿵감지기에서 확인! 💘',
          ),
          icon: const Icon(Icons.share, size: 17),
          label: const Text('친구에게 공유하기', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B9D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ]);
  }
}

class _DarkResultSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;
  const _DarkResultSection({required this.emoji, required this.title, required this.content});

  @override
  Widget build(BuildContext context) => _DarkCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DarkSectionTitle(emoji: emoji, title: title),
      const SizedBox(height: 10),
      Text(content, style: const TextStyle(fontSize: 13, height: 1.7, color: Colors.white60)),
    ]),
  );
}

class _SignalBox extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _SignalBox({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 8),
      ...items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.white60))),
        ]),
      )),
    ]),
  );
}
