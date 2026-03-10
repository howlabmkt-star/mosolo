import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/web_payment_service.dart';

/// 토스페이먼츠 결제 성공 화면
/// URL: /payment/success?paymentKey=...&orderId=...&amount=...
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String paymentKey;
  final String orderId;
  final int amount;

  const PaymentSuccessScreen({
    super.key,
    required this.paymentKey,
    required this.orderId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isConfirming = true;
  int _creditsAdded = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confirmPayment();
  }

  Future<void> _confirmPayment() async {
    try {
      final credits = await ref.read(webPaymentServiceProvider).confirmPayment(
        paymentKey: widget.paymentKey,
        orderId: widget.orderId,
        amount: widget.amount,
      );
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _creditsAdded = credits;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _error = '결제 확인 중 오류가 발생했습니다.\n고객센터에 문의해주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _isConfirming
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B9D)),
                  SizedBox(height: 20),
                  Text('결제 확인 중...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              )
            : _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text('결제 오류', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B9D), foregroundColor: Colors.white),
                      child: const Text('홈으로 돌아가기'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💘', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    const Text('결제 완료!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      '$_creditsAdded 크레딧이 충전되었습니다',
                      style: const TextStyle(fontSize: 16, color: Color(0xFFFF6B9D), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B9D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('분석 시작하기 →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 토스페이먼츠 결제 실패 화면
/// URL: /payment/fail?code=...&message=...
class PaymentFailScreen extends StatelessWidget {
  final String? errorCode;
  final String? errorMessage;

  const PaymentFailScreen({super.key, this.errorCode, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😢', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text('결제가 취소되었습니다', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '결제 중 문제가 발생했습니다',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('다시 시도하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
