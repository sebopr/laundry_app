import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Enforces a single active login per account.
///
/// Whichever device most recently signed in — or simply cold-started the
/// app with an already-persisted session — writes its own random id to
/// `users/{uid}.activeSessionId`. Every other device with that account open
/// is listening to the same document (via [AuthGate]'s snapshot stream) and
/// signs itself out the moment it sees a different id land there.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final String deviceSessionId = const Uuid().v4();

  bool _claimed = false;
  bool _kicking = false;
  bool _sawOwnClaim = false;
  bool _wasKicked = false;

  /// Writes this device's session id as the account's active session.
  /// Idempotent per app run — later calls (e.g. AuthGate rebuilding after
  /// [AuthService] already claimed at sign-in) are no-ops.
  void claimSession(String uid) {
    if (_claimed) return;
    _claimed = true;
    FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'activeSessionId': deviceSessionId},
      SetOptions(merge: true),
    ).catchError((_) => _claimed = false);
  }

  /// Feed this the latest `users/{uid}` doc data on every snapshot. Signs
  /// this device out if another device has since claimed the session.
  ///
  /// Ignores mismatches until this device has seen its own claim echoed
  /// back at least once — otherwise the stale id still on the document
  /// from *before* our write lands would immediately kick us off our own
  /// fresh login.
  void handleUserDoc(Map<String, dynamic> data) {
    if (!_claimed || _kicking) return;
    final active = data['activeSessionId'] as String?;
    if (active == deviceSessionId) {
      _sawOwnClaim = true;
      return;
    }
    if (!_sawOwnClaim || active == null) return;
    _kicking = true;
    _wasKicked = true;
    FirebaseAuth.instance.signOut();
  }

  /// Clears claim/kick state so the next login on this app run claims
  /// fresh. Call whenever the auth state drops back to signed-out.
  void reset() {
    _claimed = false;
    _kicking = false;
    _sawOwnClaim = false;
  }

  /// True exactly once right after a forced sign-out — consumed by the
  /// login screen to show an explanatory message.
  bool consumeKickedFlag() {
    if (!_wasKicked) return false;
    _wasKicked = false;
    return true;
  }
}
