import 'package:cloud_functions/cloud_functions.dart';

/// Account-lifecycle actions that need to run with elevated privilege —
/// reassigning household headship, cancelling another day's bookings,
/// deleting the Firebase Auth record itself — so both go through Cloud
/// Functions rather than direct Firestore writes from the client.
class AccountService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west6');

  /// Unlinks the caller from their current building/household (e.g. they
  /// moved out) without touching their account. If they were the household
  /// head, headship passes to another member, or the household is deleted
  /// if they were its only member. Their own future bookings are cancelled.
  static Future<void> leaveBuilding() async {
    try {
      await _functions.httpsCallable('leaveBuilding').call();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// Deletes the caller's account entirely — Firestore doc, Firebase Auth
  /// record, household/booking cleanup. Throws if they currently manage any
  /// building; they need to transfer or delete it first so it never ends up
  /// without an admin.
  static Future<void> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteAccount').call();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}
