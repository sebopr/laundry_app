import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> join(String householdId) async {
    final doc = await _db.collection('households').doc(householdId).get();
    if (!doc.exists) throw Exception('Household not found');

    final data = doc.data()!;
    await Future.wait([
      _db.collection('households').doc(householdId).update({
        'members': FieldValue.arrayUnion([_uid]),
      }),
      _db.collection('users').doc(_uid).update({
        'household_id': householdId,
        'household_name': data['name'],
        'linked_uuid': data['linked_uuid'],
        'isHouseholdHead': false,
      }),
    ]);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> stream(
          String householdId) =>
      _db.collection('households').doc(householdId).snapshots();

  static Future<List<Map<String, dynamic>>> getMembers(
      List<String> memberUids) async {
    if (memberUids.isEmpty) return [];
    final docs = await Future.wait(
        memberUids.map((uid) => _db.collection('users').doc(uid).get()));
    return docs
        .where((d) => d.exists)
        .map((d) => {'uid': d.id, ...d.data()!})
        .toList();
  }
}
