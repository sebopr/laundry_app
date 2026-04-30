import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/pages/home_page.dart';
import 'package:laundry_app/pages/onboarding_page.dart';
import 'package:laundry_app/services/auth/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (authSnap.data == null) return const LoginOrRegister();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnap.data!.uid)
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
