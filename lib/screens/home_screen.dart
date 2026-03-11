import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        '💘 솔로의 심쿵감지기',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI가 읽어드리는 그 사람의 마음',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    '무엇이 궁금하세요?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 카카오톡 분석 (메인)
                  FeatureCard(
                    icon: '💬',
                    title: '카카오톡 속마음 분석',
                    subtitle: '대화로 보는 그 사람의 진심\n무료 맛보기 → 990원 상세분석',
                    badge: '인기',
                    badgeColor: const Color(0xFFFF6B9D),
                    onTap: () => context.push('/kakao'),
                  ),
                  const SizedBox(height: 12),

                  // MBTI 궁합
                  FeatureCard(
                    icon: '🧬',
                    title: 'MBTI 궁합 팩폭',
                    subtitle: '충격적인 궁합 결과 공개\n무료 + 990원 상세 해석',
                    badge: '무료',
                    badgeColor: const Color(0xFF4CAF50),
                    onTap: () => context.push('/mbti'),
                  ),
                  const SizedBox(height: 12),

                  // 사주 연애운
                  FeatureCard(
                    icon: '🀄',
                    title: '사주로 보는 나의 연애운',
                    subtitle: '만세력 기반 실제 사주 계산\n내 연애 스타일 · 이상형 · 2025 운세',
                    badge: '무료',
                    badgeColor: const Color(0xFF8B4513),
                    onTap: () => context.push('/saju'),
                  ),
                  const SizedBox(height: 12),

                  // 이 사람, 진심일까?
                  FeatureCard(
                    icon: '🔍',
                    title: '이 사람, 진심일까?',
                    subtitle: '행동으로 읽는 진심 vs 관심없음\n무료 진단 + 990원 사주 심층 분석',
                    badge: 'NEW',
                    badgeColor: const Color(0xFF5C6BC0),
                    onTap: () => context.push('/diagnosis'),
                  ),

                  const SizedBox(height: 32),

                  // 면책 문구
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ 모든 분석 결과는 참고용이며 절대적 판단 기준이 아닙니다.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
