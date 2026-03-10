import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

final webPaymentServiceProvider = Provider<WebPaymentService>((ref) => WebPaymentService());

/// 토스페이먼츠 웹 결제 서비스
/// - API 키는 절대 Flutter 클라이언트에 저장하지 않음
/// - 결제 승인은 Cloud Functions(서버)에서 처리 (TOSS_SECRET_KEY 서버 전용)
class WebPaymentService {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  // 토스페이먼츠 클라이언트 키 (공개키 - 노출 가능)
  // 실제 배포 시: --dart-define=TOSS_CLIENT_KEY=live_ck_...
  static const _clientKey = String.fromEnvironment(
    'TOSS_CLIENT_KEY',
    defaultValue: 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eo8', // 테스트 키
  );

  static const _productPrices = {
    'credit_1': 990,
    'credit_5': 4400,
    'credit_10': 7900,
  };

  static const _productNames = {
    'credit_1': '심쿵 분석 1회권',
    'credit_5': '심쿵 분석 5회권',
    'credit_10': '심쿵 분석 10회권',
  };

  /// 토스페이먼츠 결제창 열기 (웹 전용)
  void requestPayment({required String productId, required String orderId}) {
    if (!kIsWeb) return;

    final amount = _productPrices[productId]!;
    final orderName = _productNames[productId]!;
    final origin = js.context['location']['origin'] as String;

    // dart:js로 JS 함수 호출 (시크릿 키 없음 - 클라이언트에 절대 노출 안 됨)
    js.context.callMethod('eval', ['''
      (function() {
        var tossPayments = TossPayments('$_clientKey');
        tossPayments.requestPayment('카드', {
          amount: $amount,
          orderId: '$orderId',
          orderName: '$orderName',
          customerName: '이용자',
          successUrl: '$origin/payment/success',
          failUrl: '$origin/payment/fail',
        });
      })();
    ''']);
  }

  /// 결제 승인 (Cloud Functions에서 처리 - 시크릿 키 서버 전용)
  Future<int> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final callable = _functions.httpsCallable('confirmTossPayment');
    final result = await callable.call({
      'paymentKey': paymentKey,
      'orderId': orderId,
      'amount': amount,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['creditsAdded'] as int;
  }
}
