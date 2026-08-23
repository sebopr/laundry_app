import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Requests to join a building, which need the building admin's sign-off
/// before they take effect. Households are unaffected: creating a new one
/// or joining an existing one both stay instant — the resident is already
/// building-approved by then, and joining an existing household means
/// someone there already vetted them by handing over their QR code.
///
/// Creating a request only writes the requester's own doc under
/// `join_requests`; it does not grant anything by itself. The Cloud
/// Function `onJoinRequestCreated` notifies the building's admins (push +
/// email), and only [resolve] — running server-side as `resolveJoinRequest`
/// — actually grants building access once an admin accepts.
class JoinRequestService {
  static final _db = FirebaseFirestore.instance;
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west6');

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> requestBuildingJoin(String linkedUuid) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final data = userDoc.data() ?? {};

    await _db.collection('join_requests').add({
      'uid': _uid,
      'email': data['email'] ?? FirebaseAuth.instance.currentUser?.email,
      'displayName': data['displayName'],
      'linked_uuid': linkedUuid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// The current user's most recent building-join request, or null if
  /// they've never made one. Used to show a pending/rejected state during
  /// onboarding.
  static Stream<Map<String, dynamic>?> latestForSelf() {
    return _db
        .collection('join_requests')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
      final matches =
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (matches.isEmpty) return null;

      matches.sort((a, b) {
        final at = a['createdAt'] as Timestamp?;
        final bt = b['createdAt'] as Timestamp?;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
      return matches.first;
    });
  }

  /// Pending building-join requests for a building — for the admin's
  /// approval screen.
  static Stream<List<Map<String, dynamic>>> pendingForBuilding(
      String linkedUuid) {
    return _db
        .collection('join_requests')
        .where('linked_uuid', isEqualTo: linkedUuid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) => d['status'] == 'pending')
            .toList());
  }

  /// Approves or rejects a request. Must be called by an admin who manages
  /// the request's building — enforced server-side.
  static Future<void> resolve(String requestId, bool approve) async {
    try {
      await _functions.httpsCallable('resolveJoinRequest').call({
        'requestId': requestId,
        'approve': approve,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}
