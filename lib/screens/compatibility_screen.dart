import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analysis_service.dart';
import '../services/credit_service.dart';
import '../models/compatibility_result.dart';

// ── 상태 ─────────────────────────────────────────────────────────────────────

class CompatibilityState {
  final DateTime? myBirthDate;
  final DateTime? theirBirthDate;
  final int? myBirthHour;
  final int? theirBirthHour;
  final bool isLoading;
  final CompatibilityResult? freeResult;
  final CompatibilityResult? premiumResult;
  final String? error;

  const CompatibilityState({
    this.myBirthDate,
    this.theirBirthDate,
    this.myBirthHour,
    this.theirBirthHour,
    this.isLoading = false,
    this.freeResult,
    this.premiumResult,
    this.error,
  });

  bool get canAnalyze => myBirthDate != null && theirBirthDate != null;

  CompatibilityState copyWith({
    DateTime? myBirthDate,
    DateTime? theirBirthDate,
    int? myBirthHour,
    int? theirBirthHour,
    bool? isLoading,
    CompatibilityResult? freeResult,
    CompatibilityResult? premiumResult,
    String? error,
    bool clearResults = false,
  }) => CompatibilityState(
    myBirthDate: myBirthDate ?? this.myBirthDate,
    theirBirthDate: theirBirthDate ?? this.theirBirthDate,
    myBirthHour: myBirthHour ?? this.myBirthHour,
    theirBirthHour: theirBirthHour ?? this.theirBirthHour,
    isLoading: isLoading ?? this.isLoading,
    freeResult: clearResults ? null : (freeResult ?? this.freeResult),
    premiumResult: clearResults ? null : (premiumResult ?? this.premiumResult),
    error: error,
  );
}

// ── 노티파이어 ─────────────────────────────────────────────────────────────────

class CompatibilityNotifier extends StateNotifier<CompatibilityState> {
  final AnalysisService _service;
  final CreditService _creditService;

  CompatibilityNotifier(this._service, this._creditService) : super(const CompatibilityState());

  void setMyDate(DateTime d) => state = state.copyWith(myBirthDate: d, clearResults: true);
  void setTheirDate(DateTime d) => state = state.copyWith(theirBirthDate: d, clearResults: true);
  void setMyHour(int? h) => state = state.copyWith(myBirthHour: h);
  void setTheirHour(int? h) => state = state.copyWith(theirBirthHour: h);

  String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> analyzeFree() async {
    if (!state.canAnalyze) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.analyzeCompatibility(
        myBirthDate: _fmt(state.myBirthDate!),
        theirBirthDate: _fmt(state.theirBirthDate!),
        myBirthHour: state.myBirthHour,
        theirBirthHour: state.theirBirthHour,
      );
      state = state.copyWith(isLoading: false, freeResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.');
    }
  }

  Future<void> analyzePremium() async {
    if (!state.canAnalyze) return;
    final hasCredit = await _creditService.hasCredits();
    if (!hasCredit) {
      state = state.copyWith(error: 'credit_required');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.analyzeCompatibilityPremium(
        myBirthDate: _fmt(state.myBirthDate!),
        theirBirthDate: _fmt(state.theirBirthDate!),
        myBirthHour: state.myBirthHour,
        theirBirthHour: state.theirBirthHour,
      );
      state = state.copyWith(isLoading: false, premiumResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.');
    }
  }
}

final compatibilityProvider = StateNotifierProvider.autoDispose<CompatibilityNotifier, CompatibilityState>(
  (ref) => CompatibilityNotifier(ref.read(analysisServiceProvider), ref.read(creditServiceProvider)),
);

// ── 화면 ─────────────────────────────────────────────────────────────────────

class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compatibilityProvider);
    final notifier = ref.read(compatibilityProvider.notifier);
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: CustomScrollView(
        slivers: [
          // 헤더
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B9D),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔮 생년월일 오행 궁합',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('사주팔자로 보는 진짜 연애 궁합 + 스킨십 단계',
                          style: TextStyle(fontSize: 12, color: Colors.white80)),
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

                // 입력 카드
                _InputCard(
                  label: '나의 생년월일',
                  date: state.myBirthDate,
                  hour: state.myBirthHour,
                  accentColor: const Color(0xFFFF6B9D),
                  onDatePick: notifier.setMyDate,
                  onHourChange: notifier.setMyHour,
                ),
                const SizedBox(height: 10),

                // VS 분리선
                const _VsDivider(),
                const SizedBox(height: 10),

                _InputCard(
                  label: '상대방 생년월일',
                  date: state.theirBirthDate,
                  hour: state.theirBirthHour,
                  accentColor: const Color(0xFF7B68EE),
                  onDatePick: notifier.setTheirDate,
                  onHourChange: notifier.setTheirHour,
                ),
                const SizedBox(height: 24),

                // 무료 분석 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (state.canAnalyze && !state.isLoading)
                      ? () => notifier.analyzeFree()
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: state.isLoading && state.freeResult == null
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10), Text('사주 계산 중... (20~30초)'),
                        ])
                      : const Text('🔮 무료 궁합 보기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),

                // 에러
                if (state.error != null && state.error != 'credit_required') ...[
                  const SizedBox(height: 10),
                  _ErrorBox(state.error!),
                ],

                // 무료 결과
                if (state.freeResult != null) ...[
                  const SizedBox(height: 24),
                  _FreeResultCard(result: state.freeResult!),
                  const SizedBox(height: 16),

                  // 유료 유도 배너
                  if (state.premiumResult == null) ...[
                    _PremiumUpsellCard(
                      credits: credits,
                      isLoading: state.isLoading,
                      onTap: state.error == 'credit_required'
                        ? () => context.push('/paywall')
                        : () => notifier.analyzePremium(),
                      showCreditRequired: state.error == 'credit_required',
                    ),
                  ],
                ],

                // 유료 결과
                if (state.premiumResult != null) ...[
                  const SizedBox(height: 16),
                  _PremiumResultCard(result: state.premiumResult!),
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

// ── 생년월일 입력 카드 ────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final int? hour;
  final Color accentColor;
  final ValueChanged<DateTime> onDatePick;
  final ValueChanged<int?> onHourChange;

  const _InputCard({
    required this.label,
    required this.date,
    required this.hour,
    required this.accentColor,
    required this.onDatePick,
    required this.onHourChange,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = date == null
      ? '생년월일을 선택하세요'
      : '${date!.year}년 ${date!.month}월 ${date!.day}일';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
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
                      colorScheme: ColorScheme.light(primary: accentColor),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onDatePick(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: date != null ? accentColor.withOpacity(0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: date != null ? accentColor : Colors.grey.shade300,
                    width: date != null ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month, size: 18, color: date != null ? accentColor : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 13,
                        color: date != null ? accentColor : Colors.grey,
                        fontWeight: date != null ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: DropdownButtonFormField<int?>(
              value: hour,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                isDense: true,
                hintText: '시간',
                hintStyle: const TextStyle(fontSize: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('모름', style: TextStyle(fontSize: 12))),
                ...List.generate(24, (h) => DropdownMenuItem(
                  value: h,
                  child: Text('$h시', style: const TextStyle(fontSize: 12)),
                )),
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

// ── VS 구분선 ─────────────────────────────────────────────────────────────────

class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: Colors.grey.shade300)),
    const SizedBox(width: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFF7B68EE)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('VS 💘', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800)),
    ),
    const SizedBox(width: 12),
    Expanded(child: Divider(color: Colors.grey.shade300)),
  ]);
}

// ── 무료 결과 카드 ────────────────────────────────────────────────────────────

class _FreeResultCard extends StatelessWidget {
  final CompatibilityResult result;
  const _FreeResultCard({required this.result});

  Color get _tempColor {
    if (result.compatibilityScore >= 80) return const Color(0xFFFF6B9D);
    if (result.compatibilityScore >= 60) return const Color(0xFFFF8E53);
    if (result.compatibilityScore >= 40) return const Color(0xFFFFBF00);
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _tempColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더 그라데이션
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_tempColor, _tempColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(children: [
            // 온도계 아이콘
            Text(
              result.compatibilityScore >= 80 ? '🔥' :
              result.compatibilityScore >= 60 ? '💕' :
              result.compatibilityScore >= 40 ? '🌡️' : '🥶',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.compatibilityScore}점',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              result.temperatureLabel,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
            ),
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
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 팩폭 한 줄
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
              ),
              child: Text('"${result.shockLine}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, height: 1.5, color: Color(0xFF333333)),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),

            // 요약
            Text(result.summary,
              style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF444444))),
            const SizedBox(height: 16),

            // 오행 특성 (각자)
            if (result.myElementDesc.isNotEmpty) ...[
              _ElementBox(label: '나', text: result.myElementDesc, color: const Color(0xFFFF6B9D)),
              const SizedBox(height: 8),
            ],
            if (result.theirElementDesc.isNotEmpty) ...[
              _ElementBox(label: '상대방', text: result.theirElementDesc, color: const Color(0xFF7B68EE)),
              const SizedBox(height: 16),
            ],

            // 공유 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  '🔮 생년월일 오행 궁합 결과\n\n'
                  '${result.compatibilityTag} · ${result.compatibilityScore}점\n\n'
                  '"${result.shockLine}"\n\n'
                  '${result.summary}\n\n'
                  '솔로의 심쿵감지기에서 확인! 💘',
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('결과 공유하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B9D),
                  side: const BorderSide(color: Color(0xFFFF6B9D)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ElementBox extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _ElementBox({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF444444)))),
    ]),
  );
}

// ── 유료 유도 카드 ────────────────────────────────────────────────────────────

class _PremiumUpsellCard extends StatelessWidget {
  final int credits;
  final bool isLoading;
  final VoidCallback onTap;
  final bool showCreditRequired;

  const _PremiumUpsellCard({
    required this.credits,
    required this.isLoading,
    required this.onTap,
    required this.showCreditRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF7B68EE).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('🔓', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('더 알고 싶다면? 990원으로 확인',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('지금 몇 단계까지 가도 될지 알아보세요 💘',
                  style: TextStyle(fontSize: 11, color: Colors.white60)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _UpsellChip('💑 스킨십 7단계 맞춤 추천'),
              _UpsellChip('💬 구체적 연애 조언 3가지'),
              _UpsellChip('📅 이달의 연애 운세'),
              _UpsellChip('🗺️ 맞춤 데이트 코스'),
              _UpsellChip('💪 갈등 해결 비법'),
            ],
          ),
          const SizedBox(height: 16),

          if (showCreditRequired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Text('💳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('크레딧이 부족해요', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                    GestureDetector(
                      onTap: onTap,
                      child: const Text('990원으로 충전하기 →',
                        style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ]),
                ),
              ]),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        credits > 0 ? '💑 스킨십 단계 보기 (1크레딧)' : '💑 990원으로 스킨십 단계 보기',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ]),
              ),
            ),
            if (credits > 0) ...[
              const SizedBox(height: 6),
              Center(
                child: Text('현재 $credits크레딧 보유 중',
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}

class _UpsellChip extends StatelessWidget {
  final String label;
  const _UpsellChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  );
}

// ── 유료 결과 카드 ────────────────────────────────────────────────────────────

class _PremiumResultCard extends StatelessWidget {
  final CompatibilityResult result;
  const _PremiumResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // 케미 분석
      if (result.coupleChemistry != null) ...[
        _PremiumSection(
          emoji: '✨',
          title: '우리 커플 케미 분석',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(result.coupleChemistry!, style: const TextStyle(fontSize: 14, height: 1.7)),
          ),
        ),
        const SizedBox(height: 20),
      ],

      // 스킨십 단계
      if (result.skinshipStages != null) ...[
        _PremiumSection(
          emoji: '💑',
          title: '스킨십 단계 가이드',
          child: _SkinshipStageList(
            stages: result.skinshipStages!,
            recommendedIndex: result.recommendedStageIndex ?? 2,
          ),
        ),
        const SizedBox(height: 20),
      ],

      // 연애 조언
      if (result.datingAdvice != null && result.datingAdvice!.isNotEmpty) ...[
        _PremiumSection(
          emoji: '💬',
          title: '맞춤 연애 조언',
          child: Column(
            children: result.datingAdvice!.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.6))),
              ]),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],

      // 이달의 운세
      if (result.thisMonthFortune != null) ...[
        _PremiumSection(
          emoji: '📅',
          title: '이달의 연애 운세',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7B68EE).withOpacity(0.3)),
            ),
            child: Text(result.thisMonthFortune!, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF333333))),
          ),
        ),
        const SizedBox(height: 20),
      ],

      // 데이트 코스
      if (result.bestDateIdea != null) ...[
        _PremiumSection(
          emoji: '🗺️',
          title: '이 커플 추천 데이트 코스',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
            ),
            child: Text(result.bestDateIdea!, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF2E4F34))),
          ),
        ),
        const SizedBox(height: 20),
      ],

      // 갈등 해결법
      if (result.conflictResolution != null) ...[
        _PremiumSection(
          emoji: '🤝',
          title: '갈등 해결 비법',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(result.conflictResolution!, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF5D4037))),
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 다시 공유
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final stage = result.recommendedStageIndex != null
              ? '${result.recommendedStageIndex! + 1}단계 추천'
              : '';
            Share.share(
              '🔮 생년월일 오행 궁합 상세 결과\n\n'
              '${result.compatibilityTag} · ${result.compatibilityScore}점\n'
              '"${result.shockLine}"\n\n'
              '스킨십 $stage\n\n'
              '솔로의 심쿵감지기에서 확인! 💘',
            );
          },
          icon: const Icon(Icons.share, size: 17),
          label: const Text('결과 공유하기', style: TextStyle(fontWeight: FontWeight.w700)),
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

// ── 스킨십 단계 리스트 ────────────────────────────────────────────────────────

class _SkinshipStageList extends StatelessWidget {
  final List<SkinshipStage> stages;
  final int recommendedIndex;

  const _SkinshipStageList({required this.stages, required this.recommendedIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stages.asMap().entries.map((entry) {
        final i = entry.key;
        final stage = entry.value;
        final isRecommended = i == recommendedIndex;
        final isPassed = i < recommendedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isRecommended ? const Color(0xFFFF6B9D).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecommended ? const Color(0xFFFF6B9D) : Colors.grey.shade200,
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: isRecommended ? [
              BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // 단계 원형 아이콘
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isRecommended
                    ? const Color(0xFFFF6B9D)
                    : isPassed
                      ? const Color(0xFFFF6B9D).withOpacity(0.2)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(stage.emoji, style: TextStyle(fontSize: isRecommended ? 20 : 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${stage.stage}단계 · ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    Text(stage.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRecommended ? FontWeight.w800 : FontWeight.w600,
                        color: isRecommended ? const Color(0xFFFF6B9D) : const Color(0xFF333333),
                      )),
                    if (isRecommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFF6B9D), borderRadius: BorderRadius.circular(6)),
                        child: const Text('지금 추천', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(stage.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (isRecommended && stage.tip.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('💡 ${stage.tip}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.5)),
                  ],
                ]),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── 프리미엄 섹션 래퍼 ────────────────────────────────────────────────────────

class _PremiumSection extends StatelessWidget {
  final String emoji;
  final String title;
  final Widget child;

  const _PremiumSection({required this.emoji, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF222222))),
    ]),
    const SizedBox(height: 10),
    child,
  ]);
}

// ── 에러 박스 ─────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
  );
}
