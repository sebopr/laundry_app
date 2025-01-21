import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/components/chat_bubble.dart';
import 'package:laundry_app/components/my_textfield.dart';
import 'package:laundry_app/services/auth/auth_service.dart';
import 'package:laundry_app/services/chat/chat_service.dart';

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverId;

  ChatPage({super.key, required this.receiverEmail, required this.receiverId});

//text controller
  final TextEditingController _messageController = TextEditingController();

//chat and auth services

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(receiverId, _messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(receiverEmail),
        ),
        body: Column(
          children: [
            //display the messages
            Expanded(child: _buildMessagesList()),
            //display the send field and button
            _buildMessageInput(),
          ],
        ));
  }

  Widget _buildMessagesList() {
    String senderId = _authService.getCurrentUser()!.uid; //get current user id
    return StreamBuilder(
      stream: _chatService.getMessages(senderId, receiverId),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return const Text("Error");
        }
        //loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading ...");
        }
        //return listview
        return ListView(
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data["senderId"] == _authService.getCurrentUser()!.uid;

    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(message: data["message"], isCurrentUser: isCurrentUser)
          ],
        ));
  }

  //message input

  Widget _buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: MyTextField(
            controller: _messageController,
            hintText: "Type your message",
            obscureText: false,
          ),
        ),
        //send button
        Container(
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: 25),
          child: IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.arrow_upward),
          ),
        )
      ],
    );
  }
}
