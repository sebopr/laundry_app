import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/firebase_options.dart';
import 'package:lavaplan/pages/chat_page.dart';
import 'package:lavaplan/services/notifications/notification_service.dart';

/// Must be a top-level (or static) function — the platform runs it in a
/// separate isolate when a push arrives while the app is backgrounded or
/// terminated. Android/iOS already display "notification"-payload pushes on
/// their own in that state, so there's nothing else to do here beyond
/// making sure Firebase is available if that ever changes.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Registers this device for chat push notifications and routes taps to the
/// right conversation. The actual "send a push when a message arrives"
/// half lives server-side in a Cloud Function — see functions/src/index.ts.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _listenersInitialized = false;
  String? _registeredUid;

  /// Requests notification permission, saves this device's FCM token to the
  /// user's Firestore doc, and keeps it updated if it's refreshed.
  ///
  /// Safe to call every time a signed-in user is observed (e.g. from
  /// AuthGate's build method) — a session that's already registered is a
  /// no-op, so a persisted login that never re-runs the actual sign-in flow
  /// still gets its token saved.
  Future<void> registerToken(String uid) async {
    if (_registeredUid == uid) return;
    _registeredUid = uid;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }
    messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  /// Wires up foreground display and tap-to-open-chat handling. Call this
  /// once, before `runApp`.
  void initListeners(GlobalKey<NavigatorState> navigatorKey) {
    if (_listenersInitialized) return;
    _listenersInitialized = true;
    _navigatorKey = navigatorKey;

    NotificationService.instance.onNotificationTap = (payload) {
      if (payload == null) return;
      _openChatFromData(
          Map<String, dynamic>.from(jsonDecode(payload) as Map));
    };

    // App is open and in the foreground — FCM doesn't display these on its
    // own, so show it as a local notification instead.
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final title =
          message.notification?.title ?? data['senderName'] ?? 'New message';
      final body = message.notification?.body ?? data['message'] ?? '';
      NotificationService.instance.showNow(
        id: (data['senderId'] as String?)?.hashCode ?? title.hashCode,
        title: title,
        body: body,
        payload: jsonEncode(data),
      );
    });

    // App was backgrounded and the user tapped the push.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openChatFromData(message.data);
    });

    // App was fully closed and launched by tapping the push.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openChatFromData(message.data);
    });
  }

  void _openChatFromData(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String?;
    final senderEmail = data['senderEmail'] as String?;
    if (senderId == null || senderEmail == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == senderId) return;

    _navigatorKey?.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          receiverId: senderId,
          receiverEmail: senderEmail,
          receiverName: data['senderName'] as String?,
        ),
      ),
    );
  }
}
