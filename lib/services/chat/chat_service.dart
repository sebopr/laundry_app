import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/models/message.dart';

class ChatService {
  //get instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //get user stream

  String chatRoomId = '';

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
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

  Future<void> sendMessage(String receiverId, message) async {
    //get current user info
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

//create new message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isRead: false,
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

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      "participants": {
        receiverId: {"isTyping": true}
      },
    }, SetOptions(merge: true));
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
