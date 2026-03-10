import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../models/analysis_result.dart';

class PremiumResultScreen extends StatelessWidget {
  final AnalysisResult result;

  const PremiumResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('💘 상세 분석 결과'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
              '호감도 ${result.score}점!\n"${result.summary}"\n\n솔로의 심쿵감지기로 분석해봐 💘',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ScoreCard(result: result),
          const SizedBox(height: 16),
          if (result.emotionChart != null && result.emotionChart!.isNotEmpty)
            _EmotionChartCard(points: result.emotionChart!),
          const SizedBox(height: 16),
          if (result.replyPatterns != null)
            _ReplyPatternCard(patterns: result.replyPatterns!),
          const SizedBox(height: 16),
          if (result.keywords != null && result.keywords!.isNotEmpty)
            _KeywordCard(keywords: result.keywords!),
          const SizedBox(height: 16),
          if (result.aiGuide != null)
            _AiGuideCard(guide: result.aiGuide!),
          const SizedBox(height: 16),
          if (result.prediction != null)
            _PredictionCard(prediction: result.prediction!),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '⚠️ 참고용이며 절대적 판단 기준이 아닙니다.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 호감도 점수 카드 ──────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final AnalysisResult result;
  const _ScoreCard({required this.result});

  Color get _scoreColor {
    if (result.score >= 70) return const Color(0xFFFF6B9D);
    if (result.score >= 40) return const Color(0xFFFF8E53);
    return Colors.grey;
  }

  String get _scoreEmoji {
    if (result.score >= 80) return '💘';
    if (result.score >= 60) return '💕';
    if (result.score >= 40) return '🤔';
    return '💔';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Text('$_scoreEmoji 호감도', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CircularProgressIndicator(
                  value: result.score / 100,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${result.score}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _scoreColor)),
                  const Text('/ 100', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)),
            child: Text(result.summary, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

// ── 감정 변화 그래프 ──────────────────────────────────────────────────────────

class _EmotionChartCard extends StatelessWidget {
  final List<EmotionPoint> points;
  const _EmotionChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.score))
      .toList();

    return _Card(
      title: '📈 감정 변화 그래프',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0, maxY: 1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (points.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                    return Text(points[idx].date, style: const TextStyle(fontSize: 10, color: Colors.grey));
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFFFF6B9D),
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFF6B9D).withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 답장 대기시간 ─────────────────────────────────────────────────────────────

class _ReplyPatternCard extends StatelessWidget {
  final List<ReplyPattern> patterns;
  const _ReplyPatternCard({required this.patterns});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '⏱️ 평균 답장 대기시간',
      child: Column(
        children: patterns.map((p) {
          final maxMin = patterns.map((e) => e.avgMinutes).reduce((a, b) => a > b ? a : b);
          final ratio = maxMin > 0 ? p.avgMinutes / maxMin : 0.0;
          final isMe = p.label == '나';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(isMe ? const Color(0xFF7B68EE) : const Color(0xFFFF6B9D)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  p.avgMinutes < 60
                    ? '${p.avgMinutes.toInt()}분'
                    : '${(p.avgMinutes / 60).toStringAsFixed(1)}시간',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 키워드 ────────────────────────────────────────────────────────────────────

class _KeywordCard extends StatelessWidget {
  final List<Keyword> keywords;
  const _KeywordCard({required this.keywords});

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive': return const Color(0xFF4CAF50);
      case 'negative': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '🔑 핵심 키워드',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: keywords.take(12).map((k) {
          final color = _sentimentColor(k.sentiment);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(k.word, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('${k.count}', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── AI 대화 가이드 ────────────────────────────────────────────────────────────

class _AiGuideCard extends StatelessWidget {
  final String guide;
  const _AiGuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final lines = guide.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return _Card(
      title: '💬 AI 대화 가이드',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: const BoxDecoration(color: Color(0xFFFF6B9D), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Text(e.value.replaceFirst(RegExp(r'^\d+\.\s*'), ''), style: const TextStyle(fontSize: 14, height: 1.5))),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ── 관계 발전 예측 ─────────────────────────────────────────────────────────────

class _PredictionCard extends StatelessWidget {
  final String prediction;
  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '🔮 관계 발전 예측',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFF6B9D).withOpacity(0.08), const Color(0xFF7B68EE).withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(prediction, style: const TextStyle(fontSize: 14, height: 1.7)),
      ),
    );
  }
}

// ── 공통 카드 래퍼 ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Card({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
