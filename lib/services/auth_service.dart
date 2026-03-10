import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// 익명 로그인 (앱 진입 시 자동 호출)
  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// 구글 연동 (나중에 리뷰/히스토리 저장 원할 때)
  // Future<User> signInWithGoogle() async { ... }

  Future<void> signOut() => _auth.signOut();
}
