import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis_result.dart';
import 'premium_result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 분석 기록'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: uid == null
        ? const Center(child: Text('로그인이 필요합니다'))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('analyses')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const _EmptyHistory();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _HistoryCard(doc: docs[i]),
              );
            },
          ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('아직 분석 기록이 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('카카오톡 대화를 분석해보세요!', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/kakao'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('분석 시작하기'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _HistoryCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final score = data['score'] as int? ?? 0;
    final summary = data['summary'] as String? ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null
      ? '${ts.toDate().month}/${ts.toDate().day} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
      : '';

    final color = score >= 70 ? const Color(0xFFFF6B9D)
      : score >= 40 ? const Color(0xFFFF8E53) : Colors.grey;

    // 저장된 결과로 AnalysisResult 재구성
    final result = AnalysisResult.fromJson(data);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PremiumResultScreen(result: result)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // 점수 원형
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text('$score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
