import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 사주 유료 2단계 잠금 카드 (공통 위젯)
/// RevenueCat 상품 ID: "saju_analysis_990"
class SajuPaywallCard extends StatelessWidget {
  final bool isLoading;
  final bool hasCredits;
  final int credits;
  final VoidCallback onUnlock;
  final String title;
  final List<String> features;
  final List<String> inputLabels; // 생년월일 입력 안내

  const SajuPaywallCard({
    super.key,
    required this.isLoading,
    required this.hasCredits,
    required this.credits,
    required this.onUnlock,
    this.title = '🔮 사주 심층 분석 잠금 해제',
    this.features = const [],
    this.inputLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A0DAD).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 잠금 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Text('🔮', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(
                  hasCredits ? '크레딧 ${credits}개 보유 중' : '990원 (1크레딧)',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ]),
            ),
          ]),
        ),
        // 기능 목록
        if (features.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8, runSpacing: 6,
              children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(f, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
        ],
        // 입력 안내
        if (inputLabels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Text('📅', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  inputLabels.join(' · '),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ]),
            ),
          ),
        ],
        // 잠금 해제 버튼
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A0DAD),
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6A0DAD)))
                : Text(
                    hasCredits ? '크레딧으로 사주 분석 열기 →' : '990원으로 사주 분석 열기 →',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
            ),
          ),
        ),
        if (!hasCredits)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: TextButton(
                onPressed: () => context.push('/paywall'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('크레딧 충전하기 →', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
      ]),
    );
  }
}
