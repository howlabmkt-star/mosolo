import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/credit_service.dart';
import '../services/payment_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 크레딧 현황
          _SectionHeader('💳 내 크레딧'),
          ListTile(
            leading: const Text('💳', style: TextStyle(fontSize: 24)),
            title: Text('잔여 크레딧: $credits 개'),
            subtitle: const Text('1 크레딧 = 상세 분석 1회'),
            trailing: ElevatedButton(
              onPressed: () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('충전'),
            ),
          ),
          ListTile(
            leading: const Text('🔄', style: TextStyle(fontSize: 24)),
            title: const Text('구매 복원'),
            subtitle: const Text('이전 기기에서 구매한 크레딧 복원'),
            onTap: () async {
              try {
                await ref.read(paymentServiceProvider).restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 구매 복원 완료'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복원할 구매 내역이 없습니다'), backgroundColor: Colors.orange),
                  );
                }
              }
            },
          ),

          const Divider(),
          _SectionHeader('📋 앱 정보'),
          ListTile(
            leading: const Text('🔒', style: TextStyle(fontSize: 24)),
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Text('📄', style: TextStyle(fontSize: 24)),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Text('ℹ️', style: TextStyle(fontSize: 24)),
            title: const Text('앱 버전'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),

          const Divider(),
          _SectionHeader('⚠️ 면책 사항'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '본 서비스의 모든 분석 결과는 AI에 의한 참고용 정보이며, '
              '절대적인 판단 기준이 아닙니다. '
              '실제 인간관계에서의 결정은 사용자 본인의 판단에 따라 이루어져야 합니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
    );
  }
}
