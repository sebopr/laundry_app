import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/pages/home_page.dart';
import 'package:lavaplan/pages/onboarding_page.dart';
import 'package:lavaplan/pages/verify_email_page.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/auth/login_or_register.dart';
import 'package:lavaplan/services/auth/session_service.dart';
import 'package:lavaplan/services/notifications/push_notification_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Guards against a stale, already-signed-in session whose account was
  // deleted server-side (e.g. via the admin deleteAccount function, or a
  // manual Auth console/script deletion) — the device's cached ID token
  // stays cryptographically valid for its own lifetime regardless, so
  // without this check a deleted account could keep using the app, and
  // even recreate a Firestore profile, until that token happened to expire
  // on its own. Runs once per uid per app session, same guard style as
  // registerToken/claimSession below.
  static String? _verifiedUid;

  static Future<void> _verifyAccountStillExists(User user) async {
    if (_verifiedUid == user.uid) return;
    _verifiedUid = user.uid;
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'user-disabled') {
        SessionService.instance.reset();
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges() (not authStateChanges) so the tree rebuilds when the
      // email confirmation lands and the ID token is refreshed.
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) {
          // Ready for a fresh claim next time someone signs in on this app
          // run — covers both a normal sign-out and a forced one below.
          SessionService.instance.reset();
          return const LoginOrRegister();
        }

        // Email + password accounts wait here until the address is confirmed.
        // Google and Apple users arrive already confirmed and pass straight
        // through.
        if (AuthService.needsEmailConfirmation(user)) {
          return VerifyEmailPage(user: user);
        }

        // Fire-and-forget: if this account was deleted server-side, this
        // signs the device out, which makes userChanges() emit null and
        // rebuilds this into LoginOrRegister above.
        _verifyAccountStillExists(user);

        // A no-op if this device is already registered for this uid — makes
        // sure a persisted login (no fresh sign-in call) still ends up with
        // its push token saved.
        PushNotificationService.instance.registerToken(user.uid);

        // A no-op if a sign-in on this app run already claimed the session.
        // Covers a cold start with an already-persisted login: this device
        // becomes the account's active session, and any other device still
        // signed in gets kicked out below once its own listener notices.
        SessionService.instance.claimSession(user.uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final d = userSnap.data!.data() ?? {};

            // Another device has since claimed this account's session —
            // sign this one out. AuthGate will rebuild with user == null
            // above once FirebaseAuth catches up.
            SessionService.instance.handleUserDoc(d);

            // Step 0: name
            if ((d['displayName'] as String? ?? '').isEmpty) {
              return const OnboardingPage(initialStep: 0);
            }

            // Step 1: contact details (address + phone)
            final hasAddress = (d['street'] as String? ?? '').isNotEmpty &&
                (d['houseNumber'] as String? ?? '').isNotEmpty &&
                (d['postalCode'] as String? ?? '').isNotEmpty &&
                (d['city'] as String? ?? '').isNotEmpty &&
                (d['canton'] as String? ?? '').isNotEmpty;
            final phone = d['phone'] as String? ?? '';
            if (!hasAddress || phone.isEmpty) {
              return const OnboardingPage(initialStep: 1);
            }

            // Step 2: role
            final role = d['role'] as String?;
            if (role == null) {
              return const OnboardingPage(initialStep: 2);
            }

            // Admin-only (not a resident): skip building + household steps
            final isResidentAdmin = d['isResidentAdmin'] as bool? ?? false;
            if (role == 'admin' && !isResidentAdmin) {
              return const HomePage();
            }

            // Step 3: building
            if (d['linked_uuid'] == null) {
              return const OnboardingPage(initialStep: 3);
            }

            // Step 4: household
            if (d['household_id'] == null) {
              return const OnboardingPage(initialStep: 4);
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
