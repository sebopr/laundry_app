import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lavaplan/models/message.dart';

class ChatService {
  //get instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //get user stream

  String chatRoomId = '';

  // Stream<List<Map<String, dynamic>>> getUsersStream() {
  //   return _firestore.collection("users").snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       final user = doc.data();
  //       return user;
  //     }).toList();
  //   });
  // }

  Stream<List<Map<String, dynamic>>> getUsersStream() async* {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      yield [];
      return;
    }

    // First get the current user's linked_uuid
    final currentUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    final currentUserData = currentUserDoc.data();
    final currentLinkedUuid = currentUserData?['linked_uuid'];

    if (currentLinkedUuid == null) {
      yield [];
      return;
    }

    // Now stream all users with the same linked_uuid
    yield* FirebaseFirestore.instance
        .collection("users")
        .where('linked_uuid', isEqualTo: currentLinkedUuid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final uid = doc.id;
              return {
                "uid": uid,
                ...data,
              };
            }).toList());
  }

//get unread count
  Stream<int> getUnreadCount(String currentUserId, String receiverId) {
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); //sort the ids making sure that it is the same for any two users
    chatRoomId = ids.join('_');

    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return data != null
          ? (data['participants'][currentUserId]['unreadCount'] ?? 0)
          : 0;
    });
  }

  //send message

  Future<void> sendMessage(String receiverId, message, {String? nudgeId}) async {
    //get current user info
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Contacts are only ever surfaced via getUsersStream(), which is scoped
    // to the current building — but a stale open ChatPage or a tap on an
    // old push notification can still reach here with a receiverId from a
    // building either side has since left. Re-check at send time so leaving
    // a building actually cuts off contact, not just the visible list.
    final currentLinkedUuid =
        (await _firestore.collection('users').doc(currentUserId).get())
            .data()?['linked_uuid'];
    final receiverLinkedUuid =
        (await _firestore.collection('users').doc(receiverId).get())
            .data()?['linked_uuid'];
    if (currentLinkedUuid == null ||
        currentLinkedUuid != receiverLinkedUuid) {
      throw Exception('You no longer share a building with this person.');
    }

//create new message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isRead: false,
      nudgeId: nudgeId,
    );

//add chatroom id for the users who chat together
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); //sort the ids making sure that it is the same for any two users
    chatRoomId = ids.join('_');

//add unread count to each chatroom

//add message to firestore
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());

//incrment unread message count

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      "participants": {
        receiverId: {"unreadCount": FieldValue.increment(1)}
      },
    }, SetOptions(merge: true));
  }

  /// Sends a preset [Nudge] (e.g. "you forgot your laundry") as its own
  /// chat message, using the nudge's fallback text so it still reads fine
  /// in the message list and push notification preview.
  Future<void> sendNudge(String receiverId, String nudgeId, String fallbackMessage) {
    return sendMessage(receiverId, fallbackMessage, nudgeId: nudgeId);
  }

  //receive message

  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

// Set typing status for current user in the chat room
  Future<void> setTypingStatus(String receiverId, bool isTyping) async {
    final currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      "participants": {
        currentUserId: {"isTyping": isTyping}
      },
    }, SetOptions(merge: true));
  }

// Listen to the other user's typing status
  Stream<bool> isOtherUserTyping(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return false;
      final participants = data['participants'] ?? {};
      return participants[otherUserId]?['isTyping'] ?? false;
    });
  }

  Future<void> resetUnreadCount(curentUserId, receiverId) async {
    List<String> ids = [curentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    DocumentReference docRef =
        _firestore.collection("chat_rooms").doc(chatRoomId);

    DocumentSnapshot docSnap = await docRef.get();

    if (docSnap.exists) {
      Map<String, dynamic>? data = docSnap.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey("participants")) {
        // Field exists, update it
        await docRef.update({
          "participants.$curentUserId.unreadCount": 0,
        });

//reset unread count

// Mark all unread messages as read

        var messages = await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .where('receiverId', isEqualTo: curentUserId)
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in messages.docs) {
          doc.reference.update({'isRead': true});
        }
      }
    }
  }
}
