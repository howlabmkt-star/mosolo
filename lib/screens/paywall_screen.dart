import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/payment_service.dart';
import '../services/web_payment_service.dart';
import '../services/credit_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  int _selectedPack = 0;

  final _packs = [
    {
      'label': '1회 이용권',
      'price': '990원',
      'priceNum': '990',
      'unit': '990원/건',
      'tag': '',
      'productId': 'credit_1',
      'desc': '1크레딧 · 분석 1회',
    },
    {
      'label': '5회 이용권',
      'price': '4,400원',
      'priceNum': '4400',
      'unit': '880원/건',
      'tag': '11% 할인',
      'productId': 'credit_5',
      'desc': '5크레딧 · 분석 5회',
    },
    {
      'label': '10회 이용권',
      'price': '7,900원',
      'priceNum': '7900',
      'unit': '790원/건',
      'tag': '🔥 베스트',
      'productId': 'credit_10',
      'desc': '10크레딧 · 분석 10회',
    },
  ];

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    try {
      final productId = _packs[_selectedPack]['productId']!;

      if (kIsWeb) {
        final orderId = '${productId}_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
        ref.read(webPaymentServiceProvider).requestPayment(
          productId: productId,
          orderId: orderId,
        );
        if (mounted) setState(() => _isLoading = false);
      } else {
        final service = ref.read(paymentServiceProvider);
        await service.purchaseCredits(productId);
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 헤더 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(children: [
                const Text('🔮', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                const Text(
                  '지금 궁금한 거 알아보세요',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '커피 한 잔 값으로\n그 사람의 진심과 스킨십 단계까지',
                  style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                if (credits > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF43A047).withOpacity(0.4)),
                    ),
                    child: Text('현재 $credits크레딧 보유 중',
                      style: const TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ]),
            ),

            // FOMO 사용 현황
            _FomoBanner(),
            const SizedBox(height: 20),

            // 포함 항목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1크레딧으로 할 수 있는 것',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 14),
                    const _FeatureRow('💑', '스킨십 7단계 맞춤 추천', '지금 몇 단계까지 가도 될지'),
                    const _FeatureRow('💬', '연애 조언 3가지', '구체적 행동 방법 포함'),
                    const _FeatureRow('📅', '이달의 연애 운세', '사주 기반 운세 + 행동 조언'),
                    const _FeatureRow('🗺️', '맞춤 데이트 코스', 'MBTI · 사주 기반 추천'),
                    const _FeatureRow('🔮', '전생 인연 스토리', '두 사람의 운명적 연결고리'),
                    const _FeatureRow('💬', 'AI 카카오 대화 분석', '답장패턴 · 감정그래프 · 전략'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 가격 패키지 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: List.generate(_packs.length, (i) {
                  final pack = _packs[i];
                  final isSelected = _selectedPack == i;
                  final isBest = pack['tag'] == '🔥 베스트';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPack = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? const Color(0xFFFF6B9D).withOpacity(0.12)
                          : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6B9D) : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        // 라디오
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF6B9D) : Colors.white30,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                            ? const Center(child: CircleAvatar(radius: 5, backgroundColor: Color(0xFFFF6B9D)))
                            : null,
                        ),
                        const SizedBox(width: 14),

                        // 라벨 + 설명
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(pack['label']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isSelected ? Colors.white : Colors.white70,
                                )),
                              if (pack['tag']!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBest ? const Color(0xFFFF6B9D) : const Color(0xFF43A047),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(pack['tag']!,
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ]),
                            Text(pack['unit']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ]),
                        ),

                        // 가격
                        Text(pack['price']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
                          )),
                      ]),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // 결제 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('🔓', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            '${_packs[_selectedPack]['price']}으로 잠금 해제',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  kIsWeb
                    ? '• 토스페이먼츠 안전 결제  • 크레딧 만료 없음\n• 분석 결과는 기기에 저장  • 참고용 분석입니다'
                    : '• Google Play 안전 결제  • 크레딧 만료 없음\n• 분석 결과는 기기에 저장  • 참고용 분석입니다',
                  style: const TextStyle(fontSize: 11, color: Colors.white30, height: 1.7),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FOMO 배너 ─────────────────────────────────────────────────────────────────

class _FomoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reviews = [
      ('ENFP♀', '스킨십 단계 추천이 진짜 맞아서 깜짝 놀랐어요 😱'),
      ('INTJ♂', '친구한테 절대 알려주고 싶지 않은 앱'),
      ('ISFP♀', '첫 키스 타이밍 봤는데 진짜 그날 했어요 ㅋㅋ'),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: reviews.length,
        itemBuilder: (context, i) => Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reviews[i].$1, style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B9D), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(reviews[i].$2, style: const TextStyle(fontSize: 11, color: Colors.white60, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ── 기능 행 ───────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _FeatureRow(this.emoji, this.title, this.desc);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B9D).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
          Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
      const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 18),
    ]),
  );
}
