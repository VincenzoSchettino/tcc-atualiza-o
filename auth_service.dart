import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // ================= LOGIN EMAIL =================
  Future<User?> signInWithEmail(
    String email,
    String password,
  ) async {
    if (email == 'adm@gmail.com' && password != 'root') {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Senha do administrador incorreta',
      );
    }

    final UserCredential result =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.user;
  }

  // ================= CADASTRO =================
  Future<User?> signUpWithEmail(
    String email,
    String password,
  ) async {
    final UserCredential result =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.user;
  }

  // ================= GOOGLE SIGN-IN =================
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) return null;

    if (googleUser.email == 'adm@gmail.com') {
      await _googleSignIn.signOut();
      throw FirebaseAuthException(
        code: 'admin-google-block',
        message: 'Administrador deve usar login e senha',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential =
        GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final UserCredential result =
        await _auth.signInWithCredential(credential);

    return result.user;
  }

  // ================= LOGOUT =================
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ================= RESET SENHA =================
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ================= USUÁRIO =================
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();
}
