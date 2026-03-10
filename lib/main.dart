import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Crashlytics: Flutter 에러 자동 수집
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const ProviderScope(child: SimkungApp()));
}

class SimkungApp extends ConsumerStatefulWidget {
  const SimkungApp({super.key});

  @override
  ConsumerState<SimkungApp> createState() => _SimkungAppState();
}

class _SimkungAppState extends ConsumerState<SimkungApp> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 익명 로그인 (크레딧, 기록 연동용)
    final authService = ref.read(authServiceProvider);
    if (authService.currentUser == null) {
      await authService.signInAnonymously();
    }
    // RevenueCat 초기화
    await ref.read(paymentServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) => const _AppContent();
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '솔로의 심쿵감지기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B9D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      routerConfig: appRouter,
    );
  }
}
