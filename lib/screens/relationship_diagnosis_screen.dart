import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/relationship_result.dart';
import '../services/analysis_service.dart';
import '../services/credit_service.dart';
import '../widgets/saju_paywall_card.dart';

// ── 상태 ─────────────────────────────────────────────────────────────────────

class _DiagState {
  final bool isLoading;
  final bool isSajuLoading;
  final String? error;
  final RelationshipResult? freeResult;
  final RelationshipResult? sajuResult;

  // 사주 입력 (유료 단계)
  final DateTime? myBirthDate;
  final DateTime? theirBirthDate;
  final int? myBirthHour;
  final int? theirBirthHour;

  const _DiagState({
    this.isLoading = false,
    this.isSajuLoading = false,
    this.error,
    this.freeResult,
    this.sajuResult,
    this.myBirthDate,
    this.theirBirthDate,
    this.myBirthHour,
    this.theirBirthHour,
  });

  _DiagState copyWith({
    bool? isLoading, bool? isSajuLoading, String? error,
    RelationshipResult? freeResult, RelationshipResult? sajuResult,
    DateTime? myBirthDate, DateTime? theirBirthDate,
    int? myBirthHour, int? theirBirthHour,
    bool clearError = false,
  }) => _DiagState(
    isLoading: isLoading ?? this.isLoading,
    isSajuLoading: isSajuLoading ?? this.isSajuLoading,
    error: clearError ? null : (error ?? this.error),
    freeResult: freeResult ?? this.freeResult,
    sajuResult: sajuResult ?? this.sajuResult,
    myBirthDate: myBirthDate ?? this.myBirthDate,
    theirBirthDate: theirBirthDate ?? this.theirBirthDate,
    myBirthHour: myBirthHour ?? this.myBirthHour,
    theirBirthHour: theirBirthHour ?? this.theirBirthHour,
  );

  bool get canSaju => myBirthDate != null && theirBirthDate != null;
}

class _DiagNotifier extends StateNotifier<_DiagState> {
  final AnalysisService _service;
  final CreditService _creditService;

  _DiagNotifier(this._service, this._creditService) : super(const _DiagState());

  void setMyBirthDate(DateTime d) => state = state.copyWith(myBirthDate: d);
  void setTheirBirthDate(DateTime d) => state = state.copyWith(theirBirthDate: d);
  void setMyBirthHour(int? h) => state = state.copyWith(myBirthHour: h);
  void setTheirBirthHour(int? h) => state = state.copyWith(theirBirthHour: h);

  Future<void> analyzeFree(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true, freeResult: null, sajuResult: null);
    try {
      final result = await _service.analyzeRelationship(text.trim());
      state = state.copyWith(isLoading: false, freeResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  Future<void> analyzeSaju(String behaviorText) async {
    if (!state.canSaju) return;
    final hasCredit = await _creditService.hasCredits();
    if (!hasCredit) {
      state = state.copyWith(error: 'credit_required');
      return;
    }
    state = state.copyWith(isSajuLoading: true, clearError: true);
    try {
      final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final result = await _service.analyzeRelationshipSaju(
        behaviorText: behaviorText,
        myBirthDate: fmt(state.myBirthDate!),
        theirBirthDate: fmt(state.theirBirthDate!),
        myBirthHour: state.myBirthHour,
        theirBirthHour: state.theirBirthHour,
      );
      state = state.copyWith(isSajuLoading: false, sajuResult: result);
    } catch (e) {
      final msg = e.toString().contains('resource-exhausted')
        ? '크레딧이 부족합니다. 충전 후 이용해주세요.' : '분석 중 오류가 발생했습니다.';
      state = state.copyWith(isSajuLoading: false, error: msg);
    }
  }
}

final _diagProvider = StateNotifierProvider.autoDispose<_DiagNotifier, _DiagState>(
  (ref) => _DiagNotifier(ref.read(analysisServiceProvider), ref.read(creditServiceProvider)),
);

// ── 화면 ─────────────────────────────────────────────────────────────────────

class RelationshipDiagnosisScreen extends ConsumerStatefulWidget {
  const RelationshipDiagnosisScreen({super.key});

  @override
  ConsumerState<RelationshipDiagnosisScreen> createState() => _RelationshipDiagnosisScreenState();
}

class _RelationshipDiagnosisScreenState extends ConsumerState<RelationshipDiagnosisScreen> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_diagProvider);
    final notifier = ref.read(_diagProvider.notifier);
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 이 사람, 진심일까?'),
        backgroundColor: const Color(0xFF5C6BC0),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 안내 카드
          _GuideCard(),
          const SizedBox(height: 20),

          // 텍스트 입력
          const Text('상대방의 행동을 자유롭게 써보세요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _textCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '예시:\n"카톡은 빠르게 답장하는데 먼저 연락은 절대 안 해요. 만나자고 하면 항상 ok하는데 먼저 제안하진 않아요. 가끔 제 이야기를 잘 기억하고 있더라고요..."',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey, height: 1.6),
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),

          // 무료 분석 버튼
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => notifier.analyzeFree(_textCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 10), Text('AI 분석 중...'),
                  ])
                : const Text('🔍 무료 진심 분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          // 에러
          if (state.error == 'credit_required') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
              child: Row(children: [
                const Text('💳', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('크레딧이 필요합니다', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () => context.push('/paywall'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, foregroundColor: const Color(0xFF5C6BC0)),
                    child: const Text('990원으로 크레딧 충전 →'),
                  ),
                ])),
              ]),
            ),
          ] else if (state.error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(state.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          ],

          // 무료 결과
          if (state.freeResult != null) ...[
            const SizedBox(height: 24),
            _FreeResultCard(result: state.freeResult!),
            const SizedBox(height: 20),

            // 사주 2단계 유료 잠금 (sajuResult 없을 때만)
            if (state.sajuResult == null) ...[
              const Text('📅 생년월일 입력 (사주 심층 분석용)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _BirthSection(
                label: '나의 생년월일',
                date: state.myBirthDate, hour: state.myBirthHour,
                color: const Color(0xFF5C6BC0),
                onDate: notifier.setMyBirthDate, onHour: notifier.setMyBirthHour,
              ),
              const SizedBox(height: 10),
              _BirthSection(
                label: '상대방 생년월일',
                date: state.theirBirthDate, hour: state.theirBirthHour,
                color: const Color(0xFFFF6B9D),
                onDate: notifier.setTheirBirthDate, onHour: notifier.setTheirBirthHour,
              ),
              const SizedBox(height: 14),
              SajuPaywallCard(
                isLoading: state.isSajuLoading,
                hasCredits: credits > 0,
                credits: credits,
                title: '🔮 사주로 보는 진심 심층 분석',
                features: const ['귀인 vs 악연 판정', '미래 흐름 예측', '최적 행동 타이밍', '최종 판정'],
                inputLabels: const ['나 + 상대방 생년월일 필요'],
                onUnlock: state.canSaju
                  ? () => notifier.analyzeSaju(_textCtrl.text)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('생년월일을 먼저 입력해주세요'), duration: Duration(seconds: 2))),
              ),
            ],
          ],

          // 사주 심층 결과
          if (state.sajuResult != null) ...[
            const SizedBox(height: 20),
            _SajuResultCard(result: state.sajuResult!),
          ],

          const SizedBox(height: 30),
          const Center(child: Text(
            '⚠️ 본 결과는 재미와 참고용이며, 절대적 판단 기준이 아닙니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── 안내 카드 ─────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF5C6BC0).withOpacity(0.3)),
    ),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('💡 이렇게 쓰면 더 정확해요', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      SizedBox(height: 8),
      Text(
        '• 카톡 답장 패턴 (빠름/느림/읽씹 등)\n'
        '• 만남 제안을 누가 먼저 하는지\n'
        '• 기억력 (내 말을 잘 기억하는지)\n'
        '• 스킨십 / 눈 맞춤 / 특별 대우 여부',
        style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444)),
      ),
    ]),
  );
}

// ── 생년월일 입력 ─────────────────────────────────────────────────────────────

class _BirthSection extends StatelessWidget {
  final String label;
  final DateTime? date;
  final int? hour;
  final Color color;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<int?> onHour;

  const _BirthSection({required this.label, required this.date, required this.hour,
    required this.color, required this.onDate, required this.onHour});

  @override
  Widget build(BuildContext context) {
    final text = date == null ? '생년월일 선택' : '${date!.year}년 ${date!.month}월 ${date!.day}일';
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime(1995, 1, 1),
              firstDate: DateTime(1950), lastDate: DateTime(2010),
              helpText: label,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: color)),
                child: child!,
              ),
            );
            if (picked != null) onDate(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: date != null ? color.withOpacity(0.08) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: date != null ? color : Colors.grey.shade300),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today, size: 15, color: date != null ? color : Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(text,
                style: TextStyle(fontSize: 13, color: date != null ? color : Colors.grey,
                  fontWeight: date != null ? FontWeight.w600 : FontWeight.normal))),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 84,
        child: DropdownButtonFormField<int?>(
          value: hour,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            hintText: '시간', hintStyle: const TextStyle(fontSize: 12), isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('모름', style: TextStyle(fontSize: 12))),
            ...List.generate(24, (h) => DropdownMenuItem(value: h, child: Text('$h시', style: const TextStyle(fontSize: 12)))),
          ],
          onChanged: onHour,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ),
    ]);
  }
}

// ── 무료 결과 카드 ─────────────────────────────────────────────────────────────

class _FreeResultCard extends StatelessWidget {
  final RelationshipResult result;
  const _FreeResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final tempColor = result.temperature >= 70 ? const Color(0xFFFF6B9D)
      : result.temperature >= 40 ? const Color(0xFFFF8E53) : Colors.blueGrey;
    final sincerityColor = result.sincerity == '진심' ? const Color(0xFF43A047)
      : result.sincerity == '관심없음' ? Colors.red : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFFAB47BC)]),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(children: [
            const Text('🔍 AI 진심 분석 결과', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            // 팩폭 한 줄
            if (result.shockLine.isNotEmpty)
              Text('"${result.shockLine}"',
                style: const TextStyle(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 관계 온도 게이지
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('🌡️ 관계 온도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${result.temperature}°C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tempColor)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: result.temperature / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(tempColor),
                minHeight: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('차가운 관심 ❄️', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text('불타는 진심 🔥', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 20),

            // 진심도 판정
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sincerityColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sincerityColor.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: sincerityColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(result.sincerity, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  const Text('진심 판정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                Text(result.sincerityReason, style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444))),
              ]),
            ),
            const SizedBox(height: 20),

            // 긍정 신호
            if (result.positiveSignals.isNotEmpty) ...[
              const _Label(emoji: '✅', text: '긍정적인 신호'),
              const SizedBox(height: 8),
              ...result.positiveSignals.map((s) => _BulletRow(text: s, color: const Color(0xFF43A047))),
              const SizedBox(height: 16),
            ],

            // 주의 신호
            if (result.warningSignals.isNotEmpty) ...[
              const _Label(emoji: '⚠️', text: '주의 신호'),
              const SizedBox(height: 8),
              ...result.warningSignals.map((s) => _BulletRow(text: s, color: Colors.deepOrange)),
              const SizedBox(height: 8),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── 사주 심층 결과 카드 ────────────────────────────────────────────────────────

class _SajuResultCard extends StatelessWidget {
  final RelationshipResult result;
  const _SajuResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final typeColor = result.relationshipType == '귀인' ? const Color(0xFF43A047)
      : result.relationshipType == '악연' ? Colors.red : const Color(0xFF5C6BC0);
    final typeEmoji = result.relationshipType == '귀인' ? '🌟'
      : result.relationshipType == '악연' ? '💀' : '🔗';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF5C6BC0)]),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: const Text('🔮 사주 심층 진단 결과',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 귀인 vs 악연 판정
            if (result.relationshipType != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(typeEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('이 사람은 나의 ${result.relationshipType!}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: typeColor)),
                      Text('사주 기반 판정', style: TextStyle(fontSize: 11, color: typeColor.withOpacity(0.7))),
                    ]),
                  ]),
                  if (result.relationshipTypeReason != null) ...[
                    const SizedBox(height: 12),
                    Text(result.relationshipTypeReason!,
                      style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444))),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // 미래 흐름
            if (result.futureFlow != null) ...[
              const _Label(emoji: '📈', text: '미래 관계 흐름'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFAB47BC).withOpacity(0.3)),
                ),
                child: Text(result.futureFlow!,
                  style: const TextStyle(fontSize: 13, height: 1.8, color: Color(0xFF4A148C))),
              ),
              const SizedBox(height: 20),
            ],

            // 최적 행동 타이밍
            if (result.bestTiming != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(children: [
                  const Text('⏰', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('최적 행동 타이밍', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF795548))),
                    const SizedBox(height: 4),
                    Text(result.bestTiming!, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // 최종 판정
            if (result.finalVerdict != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFFFF6B9D)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('⚖️ 최종 판정', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(result.finalVerdict!,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // 행동 조언
            if (result.adviceForUser != null) ...[
              const _Label(emoji: '💌', text: 'AI 행동 조언'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
                ),
                child: Text(result.adviceForUser!,
                  style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF1B5E20))),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── 공용 위젯 ─────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String emoji, text;
  const _Label({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF333333))),
  ]);
}

class _BulletRow extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
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
