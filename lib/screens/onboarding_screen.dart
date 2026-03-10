import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '💬',
      title: '카카오톡 대화로\n그 사람의 속마음을',
      subtitle: 'txt 파일 업로드 하나로\nAI가 30초 안에 분석해드려요',
      gradient: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    ),
    _OnboardingPage(
      emoji: '🧬',
      title: 'MBTI 궁합,\n충격적인 진실 공개',
      subtitle: '충격 팩폭 결과를 인스타·틱톡에\n공유하고 친구와 비교해보세요',
      gradient: [Color(0xFF7B68EE), Color(0xFFFF6B9D)],
    ),
    _OnboardingPage(
      emoji: '✂️',
      title: '이 관계, 계속해야 할까?\n지금 바로 확인',
      subtitle: '20개 항목 체크로\n"참으세요" vs "지금 당장 차단" 결정',
      gradient: [Color(0xFF2196F3), Color(0xFF7B68EE)],
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: '내 대화 내용은\n절대 저장되지 않아요',
      subtitle: '카카오톡 원문은 분석 즉시 삭제\n결과만 안전하게 보관됩니다',
      gradient: [Color(0xFF4CAF50), Color(0xFF2196F3)],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => _PageView(page: _pages[i]),
          ),

          // 인디케이터 + 버튼
          Positioned(
            bottom: 60, left: 24, right: 24,
            child: Column(
              children: [
                // 도트 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_currentPage == i ? 1 : 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: 32),

                // 버튼
                if (_currentPage < _pages.length - 1)
                  Row(children: [
                    TextButton(
                      onPressed: _finish,
                      child: const Text('건너뛰기', style: TextStyle(color: Colors.white70)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B9D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: const Text('다음 →', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ])
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B9D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('시작하기 💘', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _OnboardingPage page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(page.emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 40),
              Text(
                page.title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                page.subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardingPage({required this.emoji, required this.title, required this.subtitle, required this.gradient});
}
