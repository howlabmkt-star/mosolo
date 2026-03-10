import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analysis_service.dart';
import '../models/saju_result.dart';

// ── 상태 ─────────────────────────────────────────────────────────────────────

class _SajuState {
  final DateTime? birthDate;
  final int? birthHour;
  final String gender;
  final String question;
  final bool isLoading;
  final SajuResult? result;
  final String? error;

  const _SajuState({
    this.birthDate,
    this.birthHour,
    this.gender = '여',
    this.question = '',
    this.isLoading = false,
    this.result,
    this.error,
  });

  bool get canAnalyze => birthDate != null;

  _SajuState copyWith({
    DateTime? birthDate,
    int? birthHour,
    bool clearHour = false,
    String? gender,
    String? question,
    bool? isLoading,
    SajuResult? result,
    bool clearResult = false,
    String? error,
  }) => _SajuState(
    birthDate: birthDate ?? this.birthDate,
    birthHour: clearHour ? null : (birthHour ?? this.birthHour),
    gender: gender ?? this.gender,
    question: question ?? this.question,
    isLoading: isLoading ?? this.isLoading,
    result: clearResult ? null : (result ?? this.result),
    error: error,
  );
}

// ── 노티파이어 ─────────────────────────────────────────────────────────────────

class _SajuNotifier extends StateNotifier<_SajuState> {
  final AnalysisService _service;
  _SajuNotifier(this._service) : super(const _SajuState());

  void setBirthDate(DateTime d) => state = state.copyWith(birthDate: d, clearResult: true);
  void setBirthHour(int? h) => state = h == null
    ? state.copyWith(clearHour: true, clearResult: true)
    : state.copyWith(birthHour: h, clearResult: true);
  void setGender(String g) => state = state.copyWith(gender: g, clearResult: true);
  void setQuestion(String q) => state = state.copyWith(question: q);

  Future<void> analyze() async {
    if (!state.canAnalyze) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fmt = (DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final result = await _service.analyzeSaju(
        birthDate: fmt(state.birthDate!),
        birthHour: state.birthHour,
        gender: state.gender,
        question: state.question.trim().isEmpty ? null : state.question.trim(),
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '분석 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    }
  }
}

final _sajuProvider = StateNotifierProvider.autoDispose<_SajuNotifier, _SajuState>(
  (ref) => _SajuNotifier(ref.read(analysisServiceProvider)),
);

// ── 화면 ─────────────────────────────────────────────────────────────────────

class SajuScreen extends ConsumerWidget {
  const SajuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_sajuProvider);
    final notifier = ref.read(_sajuProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🀄 사주로 보는 나의 연애운'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 소개 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🀄 사주팔자로 알아보는 나의 연애 운명',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 8),
                  Text(
                    '만세력 기반 실제 사주 계산 · 오행 분석\n내가 어떤 연애를 하는 사람인지 팩폭 분석',
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 생년월일 입력
            const Text('생년월일', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _DatePickerButton(
              date: state.birthDate,
              onPick: notifier.setBirthDate,
            ),
            const SizedBox(height: 16),

            // 출생 시간
            const Text('출생 시간 (선택)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('시주 계산에 사용됩니다. 모르시면 건너뛰셔도 됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: state.birthHour,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: '시간 선택 (선택사항)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('모름 / 미입력')),
                ...List.generate(24, (h) => DropdownMenuItem(value: h, child: Text('$h시 (${_hourToJasi(h)})'))),
              ],
              onChanged: notifier.setBirthHour,
            ),
            const SizedBox(height: 16),

            // 성별
            const Text('성별', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              _GenderButton(label: '여성 👩', value: '여', selected: state.gender, onTap: notifier.setGender),
              const SizedBox(width: 12),
              _GenderButton(label: '남성 👨', value: '남', selected: state.gender, onTap: notifier.setGender),
            ]),
            const SizedBox(height: 16),

            // 궁금한 것 (선택)
            const Text('특별히 궁금한 것 (선택)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              onChanged: notifier.setQuestion,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '예: 올해 연애운이 궁금해요 / 지금 만나는 사람과 잘 될까요?',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),

            // 분석 버튼
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: (state.canAnalyze && !state.isLoading) ? () => notifier.analyze() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 10), Text('사주 계산 중... (20~30초)'),
                    ])
                  : const Text('🀄 나의 연애 사주 분석하기 (무료)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(state.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],

            if (state.result != null) ...[
              const SizedBox(height: 28),
              _SajuResultCard(result: state.result!, birthDate: state.birthDate!, gender: state.gender),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────────

String _hourToJasi(int h) {
  const jasi = ['자시', '축시', '인시', '묘시', '진시', '사시', '오시', '미시', '신시', '유시', '술시', '해시'];
  return jasi[((h + 1) ~/ 2) % 12];
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  const _DatePickerButton({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime(1995, 1, 1),
        firstDate: DateTime(1940), lastDate: DateTime(2010),
        helpText: '생년월일 선택',
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF8B4513)),
          ),
          child: child!,
        ),
      );
      if (picked != null) onPick(picked);
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: date != null ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: date != null ? const Color(0xFF8B4513) : Colors.grey.shade300,
          width: date != null ? 2 : 1,
        ),
      ),
      child: Row(children: [
        Icon(Icons.calendar_month,
          color: date != null ? const Color(0xFF8B4513) : Colors.grey, size: 22),
        const SizedBox(width: 12),
        Text(
          date != null
            ? '${date!.year}년 ${date!.month}월 ${date!.day}일'
            : '생년월일을 선택해주세요',
          style: TextStyle(
            fontSize: 15,
            fontWeight: date != null ? FontWeight.w700 : FontWeight.normal,
            color: date != null ? const Color(0xFF8B4513) : Colors.grey,
          ),
        ),
      ]),
    ),
  );
}

class _GenderButton extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _GenderButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B4513) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B4513) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            )),
        ),
      ),
    );
  }
}

// ── 결과 카드 ─────────────────────────────────────────────────────────────────

class _SajuResultCard extends StatelessWidget {
  final SajuResult result;
  final DateTime birthDate;
  final String gender;
  const _SajuResultCard({required this.result, required this.birthDate, required this.gender});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8B4513), Color(0xFFD2691E)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(children: [
            Text('🀄 ${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일생',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('사주팔자 연애운 분석',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // 팩폭 한 줄
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.4)),
              ),
              child: Text('"${result.shockLine}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                  height: 1.5, color: Color(0xFF5D2E0C)),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),

            // 사주팔자 (년월일시)
            _SectionTitle(emoji: '🗓️', title: '사주팔자 (四柱八字)'),
            const SizedBox(height: 10),
            _FourPillarsGrid(pillars: result.fourPillars),
            const SizedBox(height: 6),
            Text(result.fourPillars.summary,
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
            const SizedBox(height: 20),

            // 오행
            _SectionTitle(emoji: '🌿', title: '오행 구성 (五行)'),
            const SizedBox(height: 10),
            _FiveElementsCard(elements: result.fiveElements),
            const SizedBox(height: 20),

            // 일간 특성
            if (result.daymaster.isNotEmpty) ...[
              _SectionTitle(emoji: '☀️', title: '일간(日干) 특성'),
              const SizedBox(height: 10),
              _TextBox(text: result.daymaster, color: const Color(0xFF1976D2)),
              const SizedBox(height: 20),
            ],

            // 연애 성향
            if (result.lovePersonality.isNotEmpty) ...[
              _SectionTitle(emoji: '💕', title: '나의 연애 성향'),
              const SizedBox(height: 10),
              _TextBox(text: result.lovePersonality, color: const Color(0xFFFF6B9D)),
              const SizedBox(height: 20),
            ],

            // 이상형
            if (result.idealPartner.isNotEmpty) ...[
              _SectionTitle(emoji: '💑', title: '사주로 보는 이상형'),
              const SizedBox(height: 10),
              _TextBox(text: result.idealPartner, color: const Color(0xFF8B4513)),
              const SizedBox(height: 20),
            ],

            // 2025 연애운
            if (result.loveIn2025.isNotEmpty) ...[
              _SectionTitle(emoji: '📅', title: '2025년 연애운'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(result.loveIn2025,
                  style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF555555))),
              ),
              const SizedBox(height: 20),
            ],

            // 조언
            if (result.advice.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B4513), Color(0xFFD2691E)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('🧭', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('AI 연애 조언', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                  const SizedBox(height: 10),
                  Text(result.advice,
                    style: const TextStyle(fontSize: 13, height: 1.7, color: Colors.white)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // 공유 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    '🀄 나의 연애 사주 분석\n\n'
                    '"${result.shockLine}"\n\n'
                    '💕 연애 성향\n${result.lovePersonality}\n\n'
                    '💑 이상형\n${result.idealPartner}\n\n'
                    '솔로의 심쿵감지기에서 확인해보세요! 💘\nhttps://solo-simkung.web.app',
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('친구에게 공유하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
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

// ── 결과 서브 위젯 ─────────────────────────────────────────────────────────────

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

class _TextBox extends StatelessWidget {
  final String text;
  final Color color;
  const _TextBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444))),
  );
}

class _FourPillarsGrid extends StatelessWidget {
  final SajuFourPillars pillars;
  const _FourPillarsGrid({required this.pillars});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('년주\n(年柱)', pillars.year),
      ('월주\n(月柱)', pillars.month),
      ('일주\n(日柱)', pillars.day),
      ('시주\n(時柱)', pillars.hour),
    ];
    return Row(children: items.map((e) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(e.$2.isEmpty ? '?' : e.$2,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF5D2E0C))),
          const SizedBox(height: 4),
          Text(e.$1, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3), textAlign: TextAlign.center),
        ]),
      ),
    )).toList());
  }
}

class _FiveElementsCard extends StatelessWidget {
  final SajuFiveElements elements;
  const _FiveElementsCard({required this.elements});

  static const _elementColors = {
    '목': Color(0xFF4CAF50),
    '화': Color(0xFFFF5722),
    '토': Color(0xFFFFB300),
    '금': Color(0xFF9E9E9E),
    '수': Color(0xFF2196F3),
    '木': Color(0xFF4CAF50),
    '火': Color(0xFFFF5722),
    '土': Color(0xFFFFB300),
    '金': Color(0xFF9E9E9E),
    '水': Color(0xFF2196F3),
  };

  Color _getColor(String element) {
    for (final entry in _elementColors.entries) {
      if (element.contains(entry.key)) return entry.value;
    }
    return const Color(0xFF8B4513);
  }

  @override
  Widget build(BuildContext context) {
    final domColor = _getColor(elements.dominant);
    final lackColor = _getColor(elements.lacking);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _ElementChip(label: '강한 오행', value: elements.dominant, color: domColor),
        const SizedBox(width: 10),
        _ElementChip(label: '부족한 오행', value: elements.lacking, color: lackColor),
      ]),
      const SizedBox(height: 8),
      Text(elements.description,
        style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF555555))),
    ]);
  }
}

class _ElementChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ElementChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: color)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
    ]),
  );
}
