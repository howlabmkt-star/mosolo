import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/credit_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(creditStreamProvider).valueOrNull ?? 0;
    final viewerCount = 1847 + (DateTime.now().minute * 13 % 200);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: CustomScrollView(
        slivers: [
          // ── 히어로 헤더 ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(credits: credits, viewerCount: viewerCount),
          ),

          // ── 메인 콘텐츠 ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // 소셜 프루프
                _SocialProofBanner(viewerCount: viewerCount),
                const SizedBox(height: 20),

                // 섹션 타이틀
                const _SectionHeader(title: '무료로 먼저 확인해보세요', sub: '결과가 맘에 들면 더 깊이 파고들 수 있어요 👀'),
                const SizedBox(height: 14),

                // 카드 1: MBTI 궁합
                _MainFeatureCard(
                  gradient: const [Color(0xFF7B68EE), Color(0xFF9C88FF)],
                  icon: '🧬',
                  badge: '무료',
                  badgeColor: const Color(0xFF4CAF50),
                  title: 'MBTI 궁합 팩폭',
                  subtitle: '충격적인 궁합 결과 공개\n심쿵 포인트 · 갈등 패턴 · 대화법',
                  freeLabel: '기본 궁합 무료',
                  paidLabel: '스킨십 단계 + 데이트 코스 · 990원',
                  onTap: () => context.push('/mbti'),
                ),
                const SizedBox(height: 12),

                // 카드 2: 생년월일 궁합
                _MainFeatureCard(
                  gradient: const [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                  icon: '🔮',
                  badge: 'HOT',
                  badgeColor: const Color(0xFFFF4444),
                  title: '생년월일 오행 궁합',
                  subtitle: '사주로 보는 진짜 궁합\n스킨십 단계 추천 + 연애 조언',
                  freeLabel: '기본 궁합 온도 무료',
                  paidLabel: '스킨십 가이드 + 이달의 운세 · 990원',
                  onTap: () => context.push('/compatibility'),
                ),
                const SizedBox(height: 12),

                // 카드 3: 카카오 분석
                _MainFeatureCard(
                  gradient: const [Color(0xFFFFBF00), Color(0xFFFF8E53)],
                  icon: '💬',
                  badge: '인기',
                  badgeColor: const Color(0xFFFF6B9D),
                  title: '카카오톡 속마음 분석',
                  subtitle: '대화로 읽는 그 사람의 진심\n호감도 점수 · AI 대화 가이드',
                  freeLabel: '호감도 점수 무료',
                  paidLabel: '답장패턴 · 감정그래프 · 다음대화법 · 990원',
                  onTap: () => context.push('/kakao'),
                ),
                const SizedBox(height: 20),

                // 종합 리포트 (프리미엄 강조)
                _PremiumReportCard(onTap: () => context.push('/mix')),
                const SizedBox(height: 24),

                // 연인 MBTI 밸런스 게임 (무료 미끼)
                _CoupleGameBanner(onTap: () => context.push('/mbti')),
                const SizedBox(height: 24),

                // 신뢰 배지
                const _TrustBadges(),
                const SizedBox(height: 16),

                // 면책 문구
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ 모든 분석은 재미와 참고 목적이며 절대적 판단 기준이 아닙니다.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 히어로 헤더 ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final int credits;
  final int viewerCount;
  const _HeroHeader({required this.credits, required this.viewerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 앱명 + 크레딧
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💘 솔로의 심쿵감지기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (credits > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        const Text('💳', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text('$credits크레딧',
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // 메인 카피
              const Text(
                '그 사람, 나를\n얼마나 좋아할까?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'MBTI · 사주 · 카카오톡을 AI로 분석\n지금 무료로 확인해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // CTA 버튼
              GestureDetector(
                onTap: () => context.push('/compatibility'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔮', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('지금 바로 무료 체험',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B9D),
                        )),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFFFF6B9D)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소셜 프루프 배너 ──────────────────────────────────────────────────────────

class _SocialProofBanner extends StatelessWidget {
  final int viewerCount;
  const _SocialProofBanner({required this.viewerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔴', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 6),
          Text(
            '지금 $viewerCount명이 분석 중이에요',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B9D),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String sub;
  const _SectionHeader({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF222222))),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}

// ── 메인 피처 카드 ────────────────────────────────────────────────────────────

class _MainFeatureCard extends StatelessWidget {
  final List<Color> gradient;
  final String icon;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String freeLabel;
  final String paidLabel;
  final VoidCallback onTap;

  const _MainFeatureCard({
    required this.gradient,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.freeLabel,
    required this.paidLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            // 상단 그라데이션 영역
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                            child: Text(badge, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                ],
              ),
            ),

            // 하단 무료/유료 안내
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _PricingChip(label: freeLabel, isFree: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PricingChip(label: paidLabel, isFree: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingChip extends StatelessWidget {
  final String label;
  final bool isFree;
  const _PricingChip({required this.label, required this.isFree});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isFree ? '🆓' : '🔓', style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isFree ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ── 프리미엄 종합 리포트 카드 ─────────────────────────────────────────────────

class _PremiumReportCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumReportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7B68EE).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('종합 연애 리포트',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('MBTI + 사주 + 카카오톡 믹스 분석',
                        style: TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBF00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('1,980원', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _StarChip('스킨십 단계 맞춤 추천'),
                _StarChip('이달의 연애 운세'),
                _StarChip('데이트 코스 추천'),
                _StarChip('갈등 해결 비법'),
                _StarChip('3개월/1년 관계 예측'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✨ 지금 확인하기 (2크레딧)',
                    style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 13, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarChip extends StatelessWidget {
  final String label;
  const _StarChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
  );
}

// ── 커플 게임 배너 ────────────────────────────────────────────────────────────

class _CoupleGameBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CoupleGameBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7B68EE).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7B68EE).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🎮', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('연인 MBTI 밸런스 게임', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4A3F8F))),
                    SizedBox(width: 6),
                    _FreeBadge(),
                  ]),
                  SizedBox(height: 4),
                  Text('연인이 함께 하는 재미있는 MBTI 테스트\n서로의 선택이 얼마나 다른지 확인해보세요!',
                    style: TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF7B68EE)),
          ],
        ),
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
    child: const Text('무료', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
  );
}

// ── 신뢰 배지 ─────────────────────────────────────────────────────────────────

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _TrustItem(icon: '🔒', label: '안전 결제'),
        _TrustItem(icon: '🛡️', label: '개인정보 보호'),
        _TrustItem(icon: '🤖', label: 'AI 기반 분석'),
        _TrustItem(icon: '📱', label: '구글 플레이'),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final String icon;
  final String label;
  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
    ],
  );
}
