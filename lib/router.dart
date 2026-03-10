import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/kakao_analysis_screen.dart';
import 'screens/mbti_screen.dart';
import 'screens/breakup_calculator_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/payment_result_screen.dart';

Future<String> _initialLocation() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool('onboarding_done') ?? false;
  return done ? '/' : '/onboarding';
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    if (state.matchedLocation == '/onboarding') return null;
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done) return '/onboarding';
    return null;
  },
  routes: [
    // 온보딩
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // 메인 탭 쉘
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(path: 'kakao', builder: (_, __) => const KakaoAnalysisScreen()),
              GoRoute(path: 'mbti', builder: (_, __) => const MbtiScreen()),
              GoRoute(path: 'breakup', builder: (_, __) => const BreakupCalculatorScreen()),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'privacy', builder: (_, __) => const PrivacyPolicyScreen()),
              GoRoute(path: 'terms', builder: (_, __) => const TermsScreen()),
            ],
          ),
        ]),
      ],
    ),

    // 전체 화면 (탭 바 없이)
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
    GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),

    // 토스페이먼츠 결제 결과 (웹)
    GoRoute(
      path: '/payment/success',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return PaymentSuccessScreen(
          paymentKey: params['paymentKey'] ?? '',
          orderId: params['orderId'] ?? '',
          amount: int.tryParse(params['amount'] ?? '0') ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/payment/fail',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return PaymentFailScreen(
          errorCode: params['code'],
          errorMessage: params['message'],
        );
      },
    ),
  ],
);
