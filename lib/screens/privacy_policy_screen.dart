import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이용약관')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _TermsContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return const _PolicyBody(sections: [
      _PolicySection(
        title: '1. 수집하는 개인정보',
        content: '본 앱은 서비스 제공을 위해 최소한의 정보만 수집합니다.\n\n'
          '• 익명 인증 ID (Firebase Anonymous Auth)\n'
          '• 분석 결과 데이터 (호감도 점수, 요약 등)\n'
          '• 구매 내역 (RevenueCat을 통한 인앱결제 정보)\n'
          '• 앱 사용 통계 (Firebase Analytics, 개인 식별 불가)\n\n'
          '카카오톡 대화 원문은 수집하지 않습니다.',
      ),
      _PolicySection(
        title: '2. 카카오톡 대화 처리 방식',
        content: '• 사용자가 업로드한 카카오톡 txt 파일은 AI 분석을 위해 Firebase Cloud Functions의 메모리 내에서만 처리됩니다.\n'
          '• 분석 완료 즉시 원문 데이터는 완전히 삭제되며, 서버 또는 데이터베이스에 저장되지 않습니다.\n'
          '• Firestore에는 분석 결과(점수, 요약 등)만 저장됩니다.',
      ),
      _PolicySection(
        title: '3. 개인정보의 이용 목적',
        content: '• 서비스 제공 및 유지\n'
          '• 인앱결제 크레딧 관리\n'
          '• 분석 결과 히스토리 제공\n'
          '• 서비스 개선을 위한 통계 분석',
      ),
      _PolicySection(
        title: '4. 개인정보의 보관 기간',
        content: '• 분석 결과: 계정 삭제 시까지 보관\n'
          '• 구매 내역: 관련 법령에 따른 보관 기간\n'
          '• 앱 삭제 시 익명 계정은 자동 만료됩니다.',
      ),
      _PolicySection(
        title: '5. 제3자 서비스',
        content: '• Firebase (Google): 인증, 데이터베이스, 분석\n'
          '• OpenAI: AI 분석 처리 (원문 전달 후 즉시 삭제)\n'
          '• RevenueCat: 인앱결제 처리\n\n'
          '각 서비스의 개인정보처리방침을 참고하세요.',
      ),
      _PolicySection(
        title: '6. 이용자 권리',
        content: '이용자는 언제든지 자신의 데이터 삭제를 요청할 수 있습니다.\n'
          '앱 설정 > 계정 삭제를 통해 모든 데이터를 삭제할 수 있습니다.',
      ),
      _PolicySection(
        title: '7. 문의',
        content: '개인정보 관련 문의: support@simkung.app\n'
          '시행일: 2025년 1월 1일',
      ),
    ]);
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const _PolicyBody(sections: [
      _PolicySection(
        title: '제1조 (목적)',
        content: '본 약관은 솔로의 심쿵감지기(이하 "서비스") 이용에 관한 조건 및 절차, 이용자와 운영자의 권리·의무를 규정함을 목적으로 합니다.',
      ),
      _PolicySection(
        title: '제2조 (서비스 내용)',
        content: '서비스는 AI 기반 관계 분석 기능을 제공합니다.\n\n'
          '• 카카오톡 대화 분석 (호감도 측정)\n'
          '• MBTI 궁합 분석\n'
          '• 관계 손절 체크리스트',
      ),
      _PolicySection(
        title: '제3조 (면책 조항)',
        content: '• 모든 분석 결과는 AI에 의한 참고용 정보이며, 절대적 판단 기준이 아닙니다.\n'
          '• 서비스 이용으로 인한 인간관계 결정의 결과에 대해 운영자는 책임을 지지 않습니다.\n'
          '• 분석 결과의 정확성을 보장하지 않습니다.',
      ),
      _PolicySection(
        title: '제4조 (결제 및 환불)',
        content: '• 크레딧은 구매 즉시 제공됩니다.\n'
          '• 사용된 크레딧은 환불되지 않습니다.\n'
          '• 미사용 크레딧은 앱 삭제 시까지 유효합니다.\n'
          '• 환불은 각 스토어(Google Play, App Store)의 정책을 따릅니다.',
      ),
      _PolicySection(
        title: '제5조 (이용 제한)',
        content: '다음 행위는 금지됩니다.\n\n'
          '• 타인의 동의 없이 대화 내용 분석\n'
          '• 서비스를 통한 타인 명예 훼손\n'
          '• 서비스 역이용 또는 악용',
      ),
    ]);
  }
}

class _PolicyBody extends StatelessWidget {
  final List<_PolicySection> sections;
  const _PolicyBody({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(s.content, style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF555555))),
          ],
        ),
      )).toList(),
    );
  }
}

class _PolicySection {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});
}
