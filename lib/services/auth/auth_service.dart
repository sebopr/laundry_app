import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lavaplan/services/auth/session_service.dart';
import 'package:lavaplan/services/notifications/notification_service.dart';
import 'package:lavaplan/services/notifications/push_notification_service.dart';
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
      await sendVerificationCode();
      await NotificationService.instance
          .scheduleEmailVerificationReminder(cred.user!.uid);
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
  // Android has no native Apple ID API, so it goes through the Services ID's
  // web login flow; the redirect lands on the appleSignInCallback Cloud
  // Function (functions/src/appleSignIn.ts), which bridges it back into the
  // app. Configured to match Firebase Console → Authentication → Sign-in
  // method → Apple.

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Ignored on iOS/macOS (native Apple ID API is used there instead).
        // Android has no native API, so it opens this Services ID's web
        // login flow and relies on the Cloud Function below to bridge
        // Apple's callback back into the app.
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.example.lavaplan.signin',
          redirectUri: Uri.parse(
            'https://europe-west6-chatappdb-b4ba4.cloudfunctions.net/appleSignInCallback',
          ),
        ),
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
    await PushNotificationService.instance.registerToken(cred.user!.uid);
    // Claims this device as the account's sole active session — any other
    // device with this account open will be signed out once its listener
    // sees the id we just wrote.
    SessionService.instance.claimSession(cred.user!.uid);
  }

  // ── Email confirmation (6-digit code) ─────────────────────────────────────

  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west6');

  /// Whether [user] still has to confirm their email address.
  ///
  /// Only accounts created with an email + password need this. Google and
  /// Apple confirm the address themselves before handing it to Firebase, so
  /// those users arrive with [User.emailVerified] already true.
  static bool needsEmailConfirmation(User user) =>
      !user.emailVerified &&
      user.providerData.any((p) => p.providerId == 'password');

  /// How long the resend button should stay disabled.
  static const resendCooldown = Duration(seconds: 60);

  static DateTime? _lastCodeSentAt;

  /// Time left before another code may be requested.
  ///
  /// Tracked here rather than in the page so that a user who signs in days
  /// after registering is not made to wait for a send that already happened
  /// in a previous session. The Cloud Function applies its own throttling
  /// on top.
  static Duration get remainingResendCooldown {
    final sentAt = _lastCodeSentAt;
    if (sentAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(sentAt);
    return elapsed >= resendCooldown ? Duration.zero : resendCooldown - elapsed;
  }

  /// Requests a new 6-digit verification code be emailed to the current user.
  Future<void> sendVerificationCode() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await _functions.httpsCallable('sendVerificationCode').call();
      _lastCodeSentAt = DateTime.now();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// Submits the code the user typed. Throws with a user-facing message if
  /// it's wrong, expired, or too many attempts have been made; otherwise
  /// refreshes the local session so [FirebaseAuth.userChanges] emits and
  /// AuthGate moves past the confirmation screen.
  Future<void> verifyEmailCode(String code) async {
    try {
      await _functions.httpsCallable('verifyEmailCode').call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }

    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    await NotificationService.instance.cancelEmailVerificationReminder(user.uid);
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
