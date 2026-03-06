import 'package:firebase_auth/firebase_auth.dart';

/// Wrapper around Firebase Auth for email/password and auth state.
/// When [auth] is null (Firebase not initialized), all methods/no-op and stream emits null.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream<User?>.value(null);

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    if (_auth == null) return null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    if (_auth == null) return null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
