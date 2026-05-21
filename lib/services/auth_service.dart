import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const _desktopGoogleClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );
  static const _desktopGoogleClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );

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
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential?> createAccountWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<UserCredential?> signInWithGoogle() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    }
    return _signInWithGoogleDesktop();
  }

  static Future<UserCredential?> _signInWithGoogleDesktop() async {
    const redirectUri = 'http://localhost';

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _desktopGoogleClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'email profile openid',
      'access_type': 'offline',
      'prompt': 'select_account',
    }).toString();

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'http',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) return null;

    final tokenRes = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _desktopGoogleClientId,
        'client_secret': _desktopGoogleClientSecret,
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    final idToken = tokenData['id_token'] as String?;
    final accessToken = tokenData['access_token'] as String?;
    if (idToken == null) throw Exception('No id_token in response: $tokenData');

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken),
    );
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}