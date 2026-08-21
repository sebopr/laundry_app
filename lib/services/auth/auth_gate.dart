import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/pages/home_page.dart';
import 'package:lavaplan/pages/onboarding_page.dart';
import 'package:lavaplan/pages/verify_email_page.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/auth/login_or_register.dart';

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
        if (user == null) return const LoginOrRegister();

        // Email + password accounts wait here until the address is confirmed.
        // Google and Apple users arrive already confirmed and pass straight
        // through.
        if (AuthService.needsEmailConfirmation(user)) {
          return VerifyEmailPage(user: user);
        }

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

            // Step 0: name
            if ((d['displayName'] as String? ?? '').isEmpty) {
              return const OnboardingPage(initialStep: 0);
            }

            // Step 1: role
            final role = d['role'] as String?;
            if (role == null) {
              return const OnboardingPage(initialStep: 1);
            }

            // Admin-only (not a resident): skip building + household steps
            final isResidentAdmin = d['isResidentAdmin'] as bool? ?? false;
            if (role == 'admin' && !isResidentAdmin) {
              return const HomePage();
            }

            // Step 2: building
            if (d['linked_uuid'] == null) {
              return const OnboardingPage(initialStep: 2);
            }

            // Step 3: household
            if (d['household_id'] == null) {
              return const OnboardingPage(initialStep: 3);
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
