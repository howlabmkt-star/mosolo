import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/payment_service.dart';
import '../services/web_payment_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  int _selectedPack = 0;

  final _packs = [
    {'label': '1회 분석권', 'price': '990원', 'unit': '990원/건', 'productId': 'credit_1'},
    {'label': '5회 분석권', 'price': '4,400원', 'unit': '880원/건 (11% 할인)', 'productId': 'credit_5'},
    {'label': '10회 분석권', 'price': '7,900원', 'unit': '790원/건 (20% 할인)', 'productId': 'credit_10'},
  ];

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    try {
      final productId = _packs[_selectedPack]['productId']!;

      if (kIsWeb) {
        // 웹: 토스페이먼츠 결제창 (orderId = productId_uuid 형식)
        final orderId = '${productId}_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
        ref.read(webPaymentServiceProvider).requestPayment(
          productId: productId,
          orderId: orderId,
        );
        // 결제창이 열리며 페이지 이동됨 - 로딩만 해제
        if (mounted) setState(() => _isLoading = false);
      } else {
        // 앱: RevenueCat 인앱결제
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🔓', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('상세 분석 잠금 해제',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('커피 한 잔 가격으로 그 사람의 진심을 알아보세요',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('상세 분석에 포함된 항목', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 12),
                  _FeatureRow('⏱️', '답장 대기시간 분석', '누가 더 기다리게 하는지'),
                  _FeatureRow('🔑', '핵심 키워드 추출', '자주 사용한 단어 감정 분류'),
                  _FeatureRow('📈', '감정 변화 그래프', '날짜별 감정선 시각화'),
                  _FeatureRow('💬', 'AI 대화 가이드', '다음 대화 전략 3가지'),
                  _FeatureRow('🔮', '관계 발전 예측', '앞으로의 관계 방향'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_packs.length, (i) {
              final pack = _packs[i];
              final isSelected = _selectedPack == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedPack = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pack['label']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            Text(pack['unit']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(pack['price']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      '${_packs[_selectedPack]['price']}으로 분석 보기',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                ? '• 결제는 토스페이먼츠를 통해 안전하게 처리됩니다\n• 크레딧은 만료되지 않습니다\n• 참고용이며 절대적 판단 기준이 아닙니다'
                : '• 결제는 Google Play / App Store를 통해 처리됩니다\n• 크레딧은 만료되지 않습니다\n• 참고용이며 절대적 판단 기준이 아닙니다',
              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FeatureRow(this.emoji, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
