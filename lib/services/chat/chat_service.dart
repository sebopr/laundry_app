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
  }

  //incrment unreat message count

  Future<void> incrementUnreadCount(String currentUserId, receiverId) async {
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'participants.$receiverId.unreadCount': FieldValue.increment(1),
    });
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

//reset unread count
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'participants.$curentUserId.unreadCount': 0,
    });

// Mark all unread messages as read

    var messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      doc.reference.update({'isRead': true});
    }
  }
}
