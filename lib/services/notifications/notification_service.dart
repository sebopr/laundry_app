import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules on-device reminders — booking start/end and email
/// verification nudges. No backend involved: everything here is scheduled
/// locally and fires even if the device has no connectivity at the time.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Called with the `payload` of a local notification the user tapped —
  /// set by whoever needs to react (e.g. opening a chat thread).
  void Function(String? payload)? onNotificationTap;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) =>
          onNotificationTap?.call(response.payload),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Shows a notification immediately — used to surface a chat push while
  /// the app is in the foreground (FCM does not auto-display those).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat messages',
          channelDescription: 'New messages from your neighbours',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    // Skip reminders whose trigger time has already passed — e.g. booking
    // a slot that starts in 10 minutes shouldn't fire a "starts in 15
    // minutes" reminder in the past.
    if (fireAt.isBefore(DateTime.now())) return;

    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      // Wrapping the absolute UTC instant as a UTC TZDateTime schedules the
      // correct real-world moment without needing to detect the device's
      // IANA timezone name.
      tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'booking_reminders',
          'Booking reminders',
          channelDescription: 'Reminders about your laundry bookings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _startId(String bookingId) => bookingId.hashCode & 0x7FFFFFFF;
  int _endId(String bookingId) =>
      (bookingId.hashCode ^ 0x5A5A5A5A) & 0x7FFFFFFF;
  int _verifyId(String uid) => uid.hashCode & 0x7FFFFFFF;

  /// Schedules the "starts in 15 min" and "ends in 30 min" reminders for a
  /// newly created booking.
  Future<void> scheduleBookingReminders({
    required String bookingId,
    required int machine,
    required String slotLabel,
    required DateTime start,
    required DateTime end,
  }) async {
    await _schedule(
      id: _startId(bookingId),
      title: 'Your slot starts soon',
      body: 'Machine $machine · $slotLabel starts in 15 minutes.',
      fireAt: start.subtract(const Duration(minutes: 15)),
    );
    await _schedule(
      id: _endId(bookingId),
      title: 'Almost done',
      body:
          "Machine $machine · $slotLabel ends in 30 minutes — don't forget your laundry.",
      fireAt: end.subtract(const Duration(minutes: 30)),
    );
  }

  /// Cancels both reminders for a booking — call this when the booking is
  /// cancelled so a stale reminder doesn't fire.
  Future<void> cancelBookingReminders(String bookingId) async {
    await _plugin.cancel(_startId(bookingId));
    await _plugin.cancel(_endId(bookingId));
  }

  /// Schedules a nudge ~24h after signup if the account is still
  /// unverified by then.
  Future<void> scheduleEmailVerificationReminder(String uid) async {
    await _schedule(
      id: _verifyId(uid),
      title: 'Verify your email',
      body: 'Confirm your email address to finish setting up Lavaplan.',
      fireAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  /// Cancels the verification reminder — call this once the address is
  /// confirmed so it doesn't fire after the fact.
  Future<void> cancelEmailVerificationReminder(String uid) async {
    await _plugin.cancel(_verifyId(uid));
  }
}
