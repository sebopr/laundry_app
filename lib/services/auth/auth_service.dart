import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Email / password ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await _saveUserDoc(cred);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _saveUserDoc(cred);
      await _sendVerification(cred.user!);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _saveUserDoc(cred);
    return cred;
  }

  // ── Apple ─────────────────────────────────────────────────────────────────
  // Android requires a Service URL configured in Firebase Console under
  // Authentication → Sign-in method → Apple → Service URL.

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauthCredential);
      // Apple only sends name on the very first sign-in
      if ((cred.additionalUserInfo?.isNewUser ?? false) &&
          appleCredential.givenName != null) {
        final fullName =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                .trim();
        if (fullName.isNotEmpty) {
          await cred.user!.updateDisplayName(fullName);
        }
      }
      await _saveUserDoc(cred);
      return cred;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Future<void> _saveUserDoc(UserCredential cred) async {
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': cred.user!.email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Email confirmation ────────────────────────────────────────────────────

  /// Whether [user] still has to confirm their email address.
  ///
  /// Only accounts created with an email + password need this. Google and
  /// Apple confirm the address themselves before handing it to Firebase, so
  /// those users arrive with [User.emailVerified] already true.
  static bool needsEmailConfirmation(User user) =>
      !user.emailVerified &&
      user.providerData.any((p) => p.providerId == 'password');

  /// How long the confirmation email's resend button should stay disabled.
  static const resendCooldown = Duration(seconds: 60);

  static DateTime? _lastConfirmationSentAt;

  /// Time left before another confirmation email may be sent.
  ///
  /// Tracked here rather than in the page so that a user who signs in days
  /// after registering is not made to wait for a send that already happened
  /// in a previous session. Firebase applies its own throttling on top.
  static Duration get remainingResendCooldown {
    final sentAt = _lastConfirmationSentAt;
    if (sentAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(sentAt);
    return elapsed >= resendCooldown ? Duration.zero : resendCooldown - elapsed;
  }

  /// Sends (or re-sends) the confirmation link to the current user.
  Future<void> sendEmailConfirmation() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    await _sendVerification(user);
  }

  /// Re-reads the account from Firebase and reports whether the address has
  /// been confirmed in the meantime.
  ///
  /// [User.emailVerified] is a snapshot taken when the ID token was issued, so
  /// it never flips on its own — the account has to be reloaded. Refreshing
  /// the token afterwards makes [FirebaseAuth.userChanges] emit, which is what
  /// moves AuthGate past the confirmation screen.
  Future<bool> refreshEmailConfirmed() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null || !refreshed.emailVerified) return false;
    await refreshed.getIdToken(true);
    return true;
  }

  Future<void> _sendVerification(User user) async {
    try {
      await user.sendEmailVerification();
      _lastConfirmationSentAt = DateTime.now();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}
