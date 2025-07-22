// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:laundry_app/firebase_options.dart';
import 'package:laundry_app/services/auth/auth_gate.dart';
import 'package:laundry_app/themes/theme_provider.dart';
import 'package:laundry_app/services/conectivity/conectivity_service.dart';
import 'package:laundry_app/services/conectivity/global_overlay_wrapper.dart';

final connectivityService = ConnectivityService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectivityService(); // Singleton initializes
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      builder: (context, child) {
        return GlobalOverlayWrapper(child: child ?? const SizedBox());
      },
      home: const AuthGate(),
    );
  }
}
