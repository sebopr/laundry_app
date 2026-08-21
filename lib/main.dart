// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lavaplan/firebase_options.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/l10n/rm_fallback_localizations.dart';
import 'package:lavaplan/services/auth/auth_gate.dart';
import 'package:lavaplan/services/locale/locale_provider.dart';
import 'package:lavaplan/services/notifications/push_notification_service.dart';
import 'package:lavaplan/themes/theme_provider.dart';
import 'package:lavaplan/services/conectivity/conectivity_service.dart';
import 'package:lavaplan/services/conectivity/global_overlay_wrapper.dart';

final connectivityService = ConnectivityService();
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectivityService();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  PushNotificationService.instance.initListeners(navigatorKey);

  final localeProvider = LocaleProvider();
  await localeProvider.loadFromFirestore();

  final themeProvider = ThemeProvider();
  await themeProvider.loadFromFirestore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      locale: localeProvider.locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        ...AppLocalizations.localizationsDelegates,
        ...rmFallbackLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return GlobalOverlayWrapper(child: child ?? const SizedBox());
      },
      home: const AuthGate(),
    );
  }
}
