import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

class PaymentService {
  // RevenueCat API 키 (환경별)
  static const _rcAndroidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static const _rcIosKey = String.fromEnvironment('RC_IOS_KEY');

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);
    // 플랫폼별 키 자동 선택
    await Purchases.configure(
      PurchasesConfiguration(_rcAndroidKey.isNotEmpty ? _rcAndroidKey : _rcIosKey),
    );
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  Future<int> getCredits() async {
    final info = await getCustomerInfo();
    // Firestore에서 크레딧 잔여량 조회 (결제 webhook으로 업데이트)
    // TODO: FirestoreService와 연동
    return 0;
  }

  Future<void> purchaseCredits(String productId) async {
    final offerings = await Purchases.getOfferings();
    final offering = offerings.current;
    if (offering == null) throw Exception('상품 정보를 불러올 수 없습니다');

    final package = offering.availablePackages.firstWhere(
      (p) => p.storeProduct.identifier == productId,
      orElse: () => throw Exception('상품을 찾을 수 없습니다: $productId'),
    );

    await Purchases.purchasePackage(package);
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
