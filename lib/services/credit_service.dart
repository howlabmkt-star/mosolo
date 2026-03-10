import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditServiceProvider = Provider<CreditService>((ref) => CreditService());

/// 실시간 크레딧 스트림 (앱바 뱃지 등에서 사용)
final creditStreamProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  return FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots()
    .map((doc) => (doc.data()?['credits'] ?? 0) as int);
});

class CreditService {
  final _db = FirebaseFirestore.instance;

  Future<int> getCredits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['credits'] ?? 0) as int;
  }

  /// Cloud Functions에서 차감하지만, 클라이언트 낙관적 업데이트용
  Future<bool> hasCredits() async => (await getCredits()) > 0;
}
