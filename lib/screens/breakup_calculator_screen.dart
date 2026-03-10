import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _questions = [
  '연락이 점점 줄어들고 있다',
  '내가 연락하면 늦게 답장하거나 무시한다',
  '약속을 자주 취소하거나 미룬다',
  '내 이야기를 제대로 들어주지 않는다',
  '다른 사람과 비교를 자주 한다',
  '감정적으로 나를 무시하거나 깎아내린다',
  '거짓말이나 숨기는 것이 발견됐다',
  '내 주변 사람들을 존중하지 않는다',
  '함께 있어도 외로움을 느낀다',
  '미래에 대한 이야기를 꺼리거나 회피한다',
  '나의 감정을 표현하면 예민하다고 한다',
  '내가 희생하는 것에 감사하지 않는다',
  '갑자기 태도가 차가워졌다',
  '소셜미디어에서 나를 숨기는 것 같다',
  '나 이외의 이성에게 과도한 관심을 보인다',
  '내 결정을 무시하거나 통제하려 한다',
  '함께 있는 시간보다 혼자 있는 걸 더 선호한다',
  '대화 도중 자주 핸드폰만 본다',
  '나와의 추억에 관심이 없어 보인다',
  '이 관계를 계속해야 할지 의문이 든다',
];

class BreakupCalculatorScreen extends StatefulWidget {
  const BreakupCalculatorScreen({super.key});

  @override
  State<BreakupCalculatorScreen> createState() => _BreakupCalculatorScreenState();
}

class _BreakupCalculatorScreenState extends State<BreakupCalculatorScreen> {
  final Set<int> _checked = {};
  bool _showResult = false;

  void _calculate() {
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final score = _checked.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('✂️ 관계 손절 계산기'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _showResult
        ? _ResultView(score: score, onRetry: () => setState(() { _checked.clear(); _showResult = false; }))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (context, i) {
                    return CheckboxListTile(
                      value: _checked.contains(i),
                      onChanged: (v) => setState(() {
                        if (v == true) _checked.add(i); else _checked.remove(i);
                      }),
                      title: Text(_questions[i], style: const TextStyle(fontSize: 14, height: 1.4)),
                      activeColor: const Color(0xFF2196F3),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('${_checked.length} / ${_questions.length}개 선택됨',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('결과 보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final VoidCallback onRetry;

  const _ResultView({required this.score, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isBreak = score >= 12;
    final isWarning = score >= 7 && score < 12;

    final String emoji = isBreak ? '🚨' : isWarning ? '⚠️' : '💚';
    final String title = isBreak ? '지금 당장 차단하세요' : isWarning ? '심각하게 고려해보세요' : '조금 더 지켜보세요';
    final String subtitle = isBreak
      ? '이 관계는 당신의 정신 건강을 해치고 있습니다.\n지금 당장 거리를 두는 것이 필요합니다.'
      : isWarning
      ? '이미 여러 경고 신호가 보입니다.\n진지하게 관계를 재평가할 시점입니다.'
      : '아직 개선 가능성이 있어 보입니다.\n충분한 대화로 해결을 시도해보세요.';

    final Color color = isBreak ? Colors.red : isWarning ? Colors.orange : Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('$score / ${_questions.length}개 항목 해당',
            style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(subtitle,
              style: const TextStyle(fontSize: 15, height: 1.6),
              textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),

          // 카카오톡 분석으로 유도 (전환 CTA)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('💬 그 사람의 카톡도 분석해볼까요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('AI가 대화 패턴으로 진심을 읽어드려요',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/kakao'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6B9D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('카톡 분석 무료로 시작하기 →',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 해보기'),
          ),
          const SizedBox(height: 12),
          const Text('⚠️ 참고용이며 절대적 판단 기준이 아닙니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
