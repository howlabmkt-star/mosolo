import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/kakao_analysis_screen.dart';
import 'screens/mbti_screen.dart';
import 'screens/breakup_calculator_screen.dart';
import 'screens/result_screen.dart';
import 'screens/paywall_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/kakao',
      builder: (context, state) => const KakaoAnalysisScreen(),
    ),
    GoRoute(
      path: '/mbti',
      builder: (context, state) => const MbtiScreen(),
    ),
    GoRoute(
      path: '/breakup',
      builder: (context, state) => const BreakupCalculatorScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ResultScreen(result: extra);
      },
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);
