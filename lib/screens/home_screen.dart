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

                  // 손절 계산기
                  FeatureCard(
                    icon: '✂️',
                    title: '관계 손절 계산기',
                    subtitle: '참아야 할까? 지금 당장 차단?\n20개 항목 무료 체크',
                    badge: '완전무료',
                    badgeColor: const Color(0xFF2196F3),
                    onTap: () => context.push('/breakup'),
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
