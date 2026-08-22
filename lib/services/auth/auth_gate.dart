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
