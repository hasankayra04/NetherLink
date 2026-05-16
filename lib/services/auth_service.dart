import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  static Future<UserCredential?> signInWithEmail(
      String email, String password) async {
    return _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<UserCredential?> createAccountWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<void> signOut() => _auth.signOut();
}