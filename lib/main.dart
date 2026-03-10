import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: SimkungApp()));
}

class SimkungApp extends StatelessWidget {
  const SimkungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '솔로의 심쿵감지기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B9D), // 핑크 포인트
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      routerConfig: appRouter,
    );
  }
}
